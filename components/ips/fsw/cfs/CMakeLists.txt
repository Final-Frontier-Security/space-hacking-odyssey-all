cmake_minimum_required(VERSION 2.6.4)
project(CFS_IPS_APP C)

include(../../../ComponentSettings.cmake)

include_directories(platform_inc)
include_directories(mission_inc)
include_directories(src)
include_directories(${APPLICATION_PLATFORM_INC_LIST})

set(APP_SRC_FILES
  src/ips_app.c
)

add_cfe_app(ips ${APP_SRC_FILES})
