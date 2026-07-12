####
# F prime CMakeLists.txt:
#
# SOURCE_FILES: combined list of source and autocoding files
# MOD_DEPS: (optional) module dependencies
# UT_SOURCE_FILES: list of source files for unit tests
#
####
#ITC Changes
# include_directories("../../shared/") #device.h #cam_registers.h
# include_directories("../../standalone/") #device_cfg.h
# include_directories("../../../../../fsw/apps/hwlib/fsw/public_inc")
# include_directories("../platform_inc") #platform_cfg.h
# include_directories("../../../../../fsw/apps/hwlib/sim/inc") #nos_link.h

set(SOURCE_FILES
  "${CMAKE_CURRENT_LIST_DIR}/Arducam.fpp"
  "${CMAKE_CURRENT_LIST_DIR}/Arducam.cpp"

  # "${CMAKE_CURRENT_LIST_DIR}/../../shared/cam_device.c"
  # "${CMAKE_CURRENT_LIST_DIR}/../../shared/cam_registers.c"
  # "${CMAKE_CURRENT_LIST_DIR}/../../../../../fsw/apps/hwlib/sim/src/nos_link.c"

)

# Uncomment and add any modules that this component depends on, else
# they might not be available when cmake tries to build this component.

set(MOD_DEPS
    #     Add your dependencies here
    Fw_Types
    ${ITC_Common_LIBRARIES}
    ${NOSENGINE_LIBRARIES}
)

register_fprime_module()

target_sources(${FPRIME_CURRENT_MODULE} PRIVATE 
  "${CMAKE_CURRENT_LIST_DIR}/../../shared/cam_device.c"
  "${CMAKE_CURRENT_LIST_DIR}/../../shared/cam_registers.c"
  "${CMAKE_CURRENT_LIST_DIR}/../../../../../fsw/apps/hwlib/sim/src/nos_link.c"
)
target_include_directories(${FPRIME_CURRENT_MODULE} PRIVATE
  "../../shared/"
  "../../standalone/"
  "../../../../../fsw/apps/hwlib/fsw/public_inc"
  "../platform_inc"
  "../../../../../fsw/apps/hwlib/sim/inc"
)