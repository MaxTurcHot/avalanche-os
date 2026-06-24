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

kconfig_add_kcfg_files(CONFIG_SRCS avalanchedestroyconfig.kcfgc)

set(EFFECT_SRCS
    avalanchedestroy.cpp
    main.cpp
    ${CONFIG_SRCS}
)

add_library(kwin_effect_avalanchedestroy MODULE ${EFFECT_SRCS})

set_target_properties(kwin_effect_avalanchedestroy PROPERTIES
    PREFIX ""
    AUTOMOC ON
    AUTOUIC ON
)

target_include_directories(kwin_effect_avalanchedestroy PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(kwin_effect_avalanchedestroy PRIVATE
    KWin::kwin
    KF6::ConfigGui
    Qt6::Core
)

install(TARGETS kwin_effect_avalanchedestroy
    DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects)

install(FILES metadata.json
    DESTINATION ${KDE_INSTALL_DATADIR}/kwin/effects/avalanchedestroy)
