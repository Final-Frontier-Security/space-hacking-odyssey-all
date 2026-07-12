project(blackboard_sim)

find_package(ITC_Common REQUIRED QUIET COMPONENTS itc_logger)
find_package(NOSENGINE REQUIRED QUIET COMPONENTS common transport client uart)

include_directories(inc
                    ${sim_common_SOURCE_DIR}/inc
                    ${ITC_Common_INCLUDE_DIRS}
                    ${NOSENGINE_INCLUDE_DIRS})

set(blackboard_sim_src
    src/blackboard_hardware_model.cpp
    src/blackboard_42_data_provider.cpp
    src/blackboard_data_point.cpp
)

# For Code::Blocks and other IDEs
file(GLOB blackboard_sim_inc inc/*.hpp)

set(blackboard_sim_libs
    sim_common
    ${ITC_Common_LIBRARIES}
    ${NOSENGINE_LIBRARIES}
)

set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH}:$ORIGIN/../lib") # Pick up .so in install directory

add_library(blackboard_sim SHARED ${blackboard_sim_src} ${blackboard_sim_inc})
target_link_libraries(blackboard_sim ${blackboard_sim_libs})
install(TARGETS blackboard_sim LIBRARY DESTINATION lib ARCHIVE DESTINATION lib)
