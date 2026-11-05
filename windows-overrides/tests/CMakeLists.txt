project(tests)
include(ECMMarkAsTest)
include(ECMMarkNonGuiExecutable)

set(TEST_SOURCES
    FileSystem_test.cpp
    GZip_test.cpp
    GradleSpecifier_test.cpp
    MojangVersionFormat_test.cpp
    Library_test.cpp
    ResourceFolderModel_test.cpp
    ResourcePackParse_test.cpp
    TexturePackParse_test.cpp
    DataPackParse_test.cpp
    ShaderPackParse_test.cpp
    WorldSaveParse_test.cpp
    ParseUtils_test.cpp
    Task_test.cpp
    INIFile_test.cpp
    JavaVersion_test.cpp
    Packwiz_test.cpp
    Index_test.cpp
    Version_test.cpp
    ModrinthUrl_test.cpp
    MetaComponentParse_test.cpp
    Fabric12111Policy_test.cpp
    FpsPreset_test.cpp
    InstanceSnapshot_test.cpp
    FrameBenchmark_test.cpp
    FabricJarPolicy_test.cpp
    FeatureTools_test.cpp
    EmberAppearance_test.cpp
    Modpack12111Policy_test.cpp
    OfflineAccount_test.cpp
    CatPack_test.cpp
    XmlLogs_test.cpp
    Commandline_test.cpp
)

# NOTE(@getchoo): Very funny way of aliasing the Qt generated `main` test functions to respective filenames
# This is required for any test file passed to `create_test_sourcelist()`
foreach(src ${TEST_SOURCES})
    cmake_path(GET src STEM funcName)
    set_source_files_properties(${src} PROPERTIES COMPILE_DEFINITIONS main=${funcName})
    list(APPEND TEST_NAMES ${funcName})
endforeach()

create_test_sourcelist(DRIVER_SOURCES LauncherTests.cpp ${TEST_SOURCES})
add_executable(LauncherTests ${DRIVER_SOURCES})
target_link_libraries(LauncherTests PRIVATE Launcher_logic Qt${QT_VERSION_MAJOR}::Test)

# Add back some stuff ECMAddTests would (https://api.kde.org/ecm/module/ECMAddTests.html)
ecm_mark_as_test(LauncherTests)
# NOTE(@getchoo): This is only for parity with our previous configurations, which all had no GUI
# In the future this might change....and I don't know how to handle it right now. Have fun!
ecm_mark_nongui_executable(LauncherTests)
# "The tests will be build with -DQT_FORCE_ASSERTS to enable assertions in the test executable even for release builds"
target_compile_definitions(LauncherTests PRIVATE QT_FORCE_ASSERTS)

foreach(test ${TEST_NAMES})
    string(REPLACE "_test" "" display_name ${test})
    add_test(NAME ${display_name} COMMAND LauncherTests ${test})
endforeach()

add_executable(FabricVerificationDialogTest
    FabricVerificationDialog_test.cpp
    ../launcher/ui/dialogs/FabricVerificationDialog.cpp)
target_link_libraries(FabricVerificationDialogTest PRIVATE Qt${QT_VERSION_MAJOR}::Test Qt${QT_VERSION_MAJOR}::Widgets)
target_include_directories(FabricVerificationDialogTest PRIVATE ../launcher)
ecm_mark_as_test(FabricVerificationDialogTest)
add_test(NAME FabricVerificationDialog COMMAND FabricVerificationDialogTest)
set_tests_properties(FabricVerificationDialog PROPERTIES ENVIRONMENT "QT_QPA_PLATFORM=offscreen")

# Run explicitly inside a desktop session: QT_QPA_PLATFORM=wayland ./SkinRendererTest
add_executable(SkinRendererTest SkinRenderer_test.cpp ../launcher/resources/shaders/shaders.qrc)
target_link_libraries(SkinRendererTest PRIVATE Launcher_logic Qt${QT_VERSION_MAJOR}::Test)
ecm_mark_as_test(SkinRendererTest)

# Explicit native desktop integration check; settings are isolated in a temporary directory.
add_executable(AppearanceUiTest AppearanceUi_test.cpp)
target_link_libraries(AppearanceUiTest PRIVATE Launcher_logic Qt${QT_VERSION_MAJOR}::Test)
ecm_mark_as_test(AppearanceUiTest)


#[[
# TODO(@getchoo): Use this when we can use CMake 4.4 as our minimum version....one day
discover_tests(
    COMMAND LauncherTests
    DISCOVERY_ARGS -N
    DISCOVERY_MATCH "^(.+)$"
    TEST_NAME "\\1"
    TEST_ARGS "\\1"
)
]]#

if(WIN32)
    add_executable(WindowsFeaturesTest WindowsFeatures_test.cpp)
    target_include_directories(WindowsFeaturesTest PRIVATE ../launcher)
    target_link_libraries(WindowsFeaturesTest PRIVATE Qt6::Core Qt6::Test psapi ole32 uuid user32 shell32)
    add_test(NAME WindowsFeatures COMMAND WindowsFeaturesTest)
endif()
