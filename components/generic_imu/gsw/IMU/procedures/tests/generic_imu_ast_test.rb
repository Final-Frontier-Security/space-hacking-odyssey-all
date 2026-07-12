require 'cosmos'
require 'cosmos/script'
require "generic_imu_lib.rb"

##
## This script tests the cFS component device functionality.
## Currently this includes: 
##   Enable / disable, control hardware communications
##   Configuration, reconfigure generic_imu instrument register
##


##
## Enable / disable, control hardware communications
##
IMU_TEST_LOOP_COUNT.times do |n|
    safe_generic_imu() # Get to known state

    # Manually command to disable when already disabled
    cmd_cnt = tlm("IMU IMU_HK_TLM CMD_COUNT")
    cmd_err_cnt = tlm("IMU IMU_HK_TLM CMD_ERR_COUNT")
    cmd("IMU IMU_DISABLE_CC")
    get_generic_imu_hk()
    check("IMU IMU_HK_TLM CMD_COUNT == #{cmd_cnt}")
    check("IMU IMU_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")

    # Enable
    enable_generic_imu()

    # Confirm device counters increment without errors
    confirm_generic_imu_data_loop()

    # Manually command to enable when already enabled
    cmd_cnt = tlm("IMU IMU_HK_TLM CMD_COUNT")
    cmd_err_cnt = tlm("IMU IMU_HK_TLM CMD_ERR_COUNT")
    cmd("IMU IMU_ENABLE_CC")
    get_generic_imu_hk()
    check("IMU IMU_HK_TLM CMD_COUNT == #{cmd_cnt}")
    check("IMU IMU_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")

    # Reconfirm data remains as expected
    confirm_generic_imu_data_loop()

    # Disable
    disable_generic_imu()
end