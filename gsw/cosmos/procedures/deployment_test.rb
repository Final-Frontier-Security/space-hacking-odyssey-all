#
# Deployment Test Script
#

# Enable ADCS components
cmd("CSS_DEBUG CSS_ENABLE_CC")
cmd("FSS_DEBUG FSS_ENABLE_CC")
cmd("IMU_DEBUG IMU_ENABLE_CC")
cmd("MAG_DEBUG MAG_ENABLE_CC")
cmd("TORQUER_DEBUG TORQUER_ENABLE_CC")
cmd("NOVATEL_OEM615_DEBUG NOVATEL_OEM615_ENABLE_CC")
wait(3)

# Prepare scenario, i.e. spin up spacecraft
cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE 2")
wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_X", -0.10, 0.01, 120)
cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE 0")

cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE 4")
wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Y", -0.10, 0.01, 120)
cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE 0")

cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE -6")
wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Z", 0.10, 0.01, 120)
cmd("REACTION_WHEEL_DEBUG RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE 0")
wait(10)

## Enable BDOT mode to detumble
#cmd("ADCS_DEBUG ADCS_SET_MODE_CC with GNC_MODE 'BDOT_MODE'")
#wait(3)
#
## Wait on transition until all axis reported under 3 degrees angular rate
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_X", 0.0, 0.015, 120)
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Y", 0.0, 0.015, 120)
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Z", 0.0, 0.015, 120)
#
## Check again to be sure
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_X", 0.0, 0.015, 10)
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Y", 0.0, 0.015, 10)
#wait_check_tolerance("ADCS_DEBUG ADCS_AD WBN_Z", 0.0, 0.015, 10)

# Set sun safe mode
cmd("ADCS_DEBUG ADCS_SET_MODE_CC with GNC_MODE 'SUNSAFE_MODE'")
