cmake_minimum_required(VERSION 3.16)

project(onedrive-plasmoid)

set(PROJECT_VERSION "3.0.0")

find_package(ECM 5.240.0 QUIET NO_MODULE)
if (ECM_FOUND)
    set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})
    include(KDEInstallDirs)
    include(KDECMakeSettings)
    include(KDECompilerSettings NO_POLICY_SCOPE)

    plasma_install_package(. org.kde.plasma.onedrive)
else()
    # Fallback installation paths when building without ECM
    if(NOT DEFINED KDE_INSTALL_DATADIR)
        set(KDE_INSTALL_DATADIR "${CMAKE_INSTALL_PREFIX}/share")
    endif()

    install(DIRECTORY contents metadata.json images
            DESTINATION "${KDE_INSTALL_DATADIR}/plasma/plasmoids/org.kde.plasma.onedrive"
            PATTERN "CMakeLists.txt" EXCLUDE)
endif()
