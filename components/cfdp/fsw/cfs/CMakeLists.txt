cmake_minimum_required(VERSION 2.6.4)
project(CFS_CFDP_APP C)

include(../../../ComponentSettings.cmake)

include_directories(platform_inc)
include_directories(mission_inc)
include_directories(src)
include_directories(${APPLICATION_PLATFORM_INC_LIST})

set(APP_SRC_FILES
  src/cfdp_app.c
  src/cfdp_cfdp.c
  src/cfdp_cmd.c
)

# Create the app module
add_cfe_app(cfdp ${APP_SRC_FILES})
