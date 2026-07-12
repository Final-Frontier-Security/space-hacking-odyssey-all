require 'cosmos'
require 'cosmos/script'
require "generic_thruster_lib.rb"

##
## This script tests the cFS component in an automated scenario.
## Currently this includes: 
##   Hardware failure
##   Hardware status reporting fault
##

##
## Hardware failure
##
#THRUSTER_TEST_LOOP_COUNT.times do |n|
#    # Prepare
#    generic_thruster_prepare_ast()
#
#    # Disable sim and confirm device error counts increase
#    dev_cmd_cnt = tlm("THRUSTER THRUSTER_HK_TLM DEVICE_COUNT")
#    dev_cmd_err_cnt = tlm("THRUSTER THRUSTER_HK_TLM DEVICE_ERR_COUNT")
#    generic_thruster_sim_disable()
#    check("THRUSTER THRUSTER_HK_TLM DEVICE_COUNT == #{dev_cmd_cnt}")
#    check("THRUSTER THRUSTER_HK_TLM DEVICE_ERR_COUNT >= #{dev_cmd_err_cnt}")
#
#    # Enable sim and confirm return to nominal operation
#    generic_thruster_sim_enable()
#    confirm_generic_thruster_data_loop()
#end