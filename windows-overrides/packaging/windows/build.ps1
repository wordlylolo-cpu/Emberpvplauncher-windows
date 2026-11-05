param([string]$QtRoot=$env:QT_ROOT_DIR,[string]$Configuration='Release',[switch]$SkipTests)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if (-not $IsWindows) { throw 'Run this build script on Windows.' }
$SourceRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$Build=Join-Path $SourceRoot 'build-windows'
$Package=Join-Path $SourceRoot 'dist/windows11-x64'
if (-not $QtRoot) { throw 'Set QT_ROOT_DIR to the MSVC 2022 x64 Qt installation.' }
if (-not $env:JAVA_HOME -or -not (Test-Path "$env:JAVA_HOME/bin/javac.exe")) { throw 'A JDK 17 compiler is required.' }
$Vcpkg=Join-Path $SourceRoot 'cmake/vcpkg'
if (-not (Test-Path "$Vcpkg/scripts/buildsystems/vcpkg.cmake")) { throw 'The pinned vcpkg dependency must be checked out at cmake/vcpkg.' }
function Invoke-Checked([string]$Command,[string[]]$CommandArguments) {
    & $Command @CommandArguments
    if ($LASTEXITCODE -ne 0) { throw "$Command failed with exit code $LASTEXITCODE" }
}
if (-not (Test-Path "$Vcpkg/vcpkg.exe")) { Invoke-Checked "$Vcpkg/bootstrap-vcpkg.bat" @('-disableMetrics') }
$CmakeArgs=@('-S',$SourceRoot,'-B',$Build,'-G','Ninja Multi-Config',"-DCMAKE_TOOLCHAIN_FILE=$Vcpkg/scripts/buildsystems/vcpkg.cmake",'-DVCPKG_TARGET_TRIPLET=x64-windows','-DVCPKG_HOST_TRIPLET=x64-windows',"-DCMAKE_PREFIX_PATH=$QtRoot",'-DBUILD_TESTING=ON','-DLauncher_WARNING_AS_ERROR=OFF','-DLauncher_ENABLE_JAVA_DOWNLOADER=ON','-DLauncher_BUILD_PLATFORM=windows11-x64','-DLauncher_UPDATER_GITHUB_REPO=','-DLauncher_BUILD_ARTIFACT=',"-DCMAKE_INSTALL_PREFIX=$Package", "-DJava_JAVAC_EXECUTABLE=$env:JAVA_HOME/bin/javac.exe","-DJava_JAVA_EXECUTABLE=$env:JAVA_HOME/bin/java.exe","-DJava_JAR_EXECUTABLE=$env:JAVA_HOME/bin/jar.exe")
if ($env:EMBERPVP_MSA_CLIENT_ID) { $CmakeArgs+="-DLauncher_MSA_CLIENT_ID=$env:EMBERPVP_MSA_CLIENT_ID" }
if ($env:EMBERPVP_CURSEFORGE_API_KEY) { $CmakeArgs+="-DLauncher_CURSEFORGE_API_KEY=$env:EMBERPVP_CURSEFORGE_API_KEY" }
Invoke-Checked 'cmake' $CmakeArgs
Invoke-Checked 'cmake' @('--build',$Build,'--config',$Configuration,'--parallel','4')
$env:PATH="$QtRoot/bin;$Build/vcpkg_installed/x64-windows/bin;$env:PATH"
if (-not $SkipTests) { Invoke-Checked 'ctest' @('--test-dir',$Build,'--build-config',$Configuration,'--output-on-failure','--timeout','180') }
Invoke-Checked 'cmake' @('--install',$Build,'--config',$Configuration)
# App-local MSVC runtime lets the launcher run without an administrator-installed prerequisite.
$RuntimeRoot=$env:VCToolsRedistDir
if (-not $RuntimeRoot) { throw 'Use the x64 Native Tools/Developer shell from Visual Studio 2022.' }
$Runtime=Get-ChildItem "$RuntimeRoot/x64" -Directory -Filter 'Microsoft.VC*.CRT' | Select-Object -First 1
if (-not $Runtime) { throw 'Could not find the distributable x64 MSVC runtime.' }
Copy-Item "$($Runtime.FullName)/*.dll" $Package -Force
if (Test-Path "$QtRoot/bin/opengl32sw.dll") { Copy-Item "$QtRoot/bin/opengl32sw.dll" $Package -Force }
foreach ($Required in @('emberpvp-launcher.exe','Qt6Core.dll','Qt6Gui.dll','Qt6Widgets.dll','Qt6Network.dll','Qt6NetworkAuth.dll','platforms/qwindows.dll','vcruntime140.dll','msvcp140.dll','jars/NewLaunch.jar','jars/JavaCheck.jar')) {
    if (-not (Test-Path (Join-Path $Package $Required))) { throw "Incomplete package: $Required is missing." }
}
Copy-Item "$SourceRoot/LICENSE" "$Package/LICENSE.txt"
Copy-Item "$SourceRoot/COPYING.md" "$Package/COPYING.md"
$Licenses=New-Item "$Package/licenses" -ItemType Directory -Force
foreach ($Copyright in Get-ChildItem "$Build/vcpkg_installed/x64-windows/share/*/copyright" -ErrorAction SilentlyContinue) {
    Copy-Item $Copyright.FullName (Join-Path $Licenses ($Copyright.Directory.Name+'.txt'))
}
foreach ($Candidate in @("$QtRoot/LICENSES","$QtRoot/licenses","$QtRoot/../../Licenses")) {
    if (Test-Path $Candidate) { Copy-Item $Candidate "$Package/licenses/Qt" -Recurse -Force; break }
}
@'
Emberpvp Launcher - Windows 11 x64
Minecraft Java 1.21.11 + Fabric only.
Run emberpvp-launcher.exe. Keep the DLLs, plugins and jars beside it.
Your accounts and worlds are personal data and are not included in this package.
Normal launching uses your Windows user account and does not request administrator access.
This is an independent GPL-3.0-only Prism Launcher fork; upstream notices are in COPYING.md.
Source and build instructions are in Source/ when packaged by the release workflow.
CurseForge integration needs a separately configured Emberpvp API key. Modrinth works without one.
'@ | Set-Content "$Package/READ-ME.txt" -Encoding utf8
Write-Host "Windows package prepared at $Package"
