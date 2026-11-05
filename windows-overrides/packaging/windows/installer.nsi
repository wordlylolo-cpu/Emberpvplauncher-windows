!include "MUI2.nsh"
!include "x64.nsh"
Unicode true
SetCompressor /SOLID lzma
Name "Emberpvp Launcher"
OutFile "${OUTPUT_EXE}"
InstallDir "$LOCALAPPDATA\Programs\EmberpvpLauncher"
RequestExecutionLevel user
!define MUI_ICON "${SOURCE_DIR}\program_info\emberpvp-launcher.ico"
!define MUI_ABORTWARNING
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${PACKAGE_DIR}\LICENSE.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\emberpvp-launcher.exe"
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"
VIProductVersion "0.1.0.0"
VIAddVersionKey /LANG=1033 "ProductName" "Emberpvp Launcher"
VIAddVersionKey /LANG=1033 "FileDescription" "Emberpvp Launcher for Windows 11 x64"
VIAddVersionKey /LANG=1033 "FileVersion" "0.1.0.0"
VIAddVersionKey /LANG=1033 "LegalCopyright" "Emberpvp and Prism Launcher contributors. GPL-3.0-only."
Section "Emberpvp Launcher" MainSection
  SectionIn RO
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "This build requires 64-bit Windows."
    Abort
  ${EndIf}
  SetRegView 64
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File /r "${PACKAGE_DIR}\*.*"
  CreateDirectory "$SMPROGRAMS\Emberpvp Launcher"
  CreateShortCut "$SMPROGRAMS\Emberpvp Launcher\Emberpvp Launcher.lnk" "$INSTDIR\emberpvp-launcher.exe"
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EmberpvpLauncher" "DisplayName" "Emberpvp Launcher"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EmberpvpLauncher" "UninstallString" "$\"$INSTDIR\Uninstall.exe$\""
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EmberpvpLauncher" "DisplayVersion" "0.1.0"
SectionEnd
Section /o "Desktop shortcut"
  CreateShortCut "$DESKTOP\Emberpvp Launcher.lnk" "$INSTDIR\emberpvp-launcher.exe"
SectionEnd
Section "Uninstall"
  SetShellVarContext current
  SetRegView 64
  !include "${UNINSTALL_FILES}"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\Emberpvp Launcher.lnk"
  Delete "$SMPROGRAMS\Emberpvp Launcher\Emberpvp Launcher.lnk"
  RMDir "$SMPROGRAMS\Emberpvp Launcher"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\EmberpvpLauncher"
SectionEnd
