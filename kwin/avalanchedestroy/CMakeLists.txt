cmake_minimum_required(VERSION 3.16)
project(avalanchedestroy VERSION 1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(KF6 REQUIRED COMPONENTS Config)
find_package(KWin REQUIRED)

include(KWinEffectsMacros)

kconfig_add_kcfg_files(SOURCES avalanchedestroyconfig.kcfgc)

list(APPEND SOURCES
    avalanchedestroy.cpp
    main.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/avalanchedestroyconfig.cpp
)

kwin_add_effect_with_config(avalanchedestroy ${SOURCES})

target_include_directories(avalanchedestroy PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

target_link_libraries(avalanchedestroy PRIVATE
    KWin::kwin
    KF6::ConfigGui
)

install(FILES metadata.json
    DESTINATION ${KDE_INSTALL_DATADIR}/kwin/effects/avalanchedestroy)
