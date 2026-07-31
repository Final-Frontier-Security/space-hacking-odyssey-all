cmake_minimum_required(VERSION 2.6.4)
project(CFS_IDS_APP C)

include(../../../ComponentSettings.cmake)

include_directories(platform_inc)
include_directories(mission_inc)
include_directories(src)
include_directories(${APPLICATION_PLATFORM_INC_LIST})

set(APP_SRC_FILES
  src/ids_app.c
)

add_cfe_app(ids ${APP_SRC_FILES})
