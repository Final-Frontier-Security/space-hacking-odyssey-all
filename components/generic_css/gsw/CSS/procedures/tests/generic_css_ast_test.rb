require 'cosmos'
require 'cosmos/script'
require "generic_css_lib.rb"

##
## This script tests the cFS component in an automated scenario.
## Currently this includes: 
##   Hardware failure
##   Hardware status reporting fault
##


##
## Hardware failure
##
CSS_TEST_LOOP_COUNT.times do |n|
    # Prepare
    generic_css_prepare_ast()

    # Disable sim and confirm device error counts increase
    dev_cmd_cnt = tlm("CSS CSS_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("CSS CSS_HK_TLM DEVICE_ERR_COUNT")
    generic_css_sim_disable()
    check("CSS CSS_HK_TLM DEVICE_COUNT == #{dev_cmd_cnt}")
    check("CSS CSS_HK_TLM DEVICE_ERR_COUNT >= #{dev_cmd_err_cnt}")

    # Enable sim and confirm return to nominal operation
    generic_css_sim_enable()
    confirm_generic_css_data_loop()
end
