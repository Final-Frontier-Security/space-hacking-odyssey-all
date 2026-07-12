# Library for EPS Target
require 'cosmos'
require 'cosmos/script'

#
# Definitions
#
EPS_CMD_SLEEP = 0.25
EPS_RESPONSE_TIMEOUT = 5
EPS_TEST_LOOP_COUNT = 1
EPS_DEVICE_LOOP_COUNT = 5

#
# Functions
#
def get_eps_hk()
    cmd("EPS EPS_REQ_HK")
    wait_check_packet("EPS", "EPS_HK_TLM", 1, EPS_RESPONSE_TIMEOUT)
    sleep(EPS_CMD_SLEEP)
end

dev_cmd_cnt = tlm("EPS EPS_HK_TLM DEVICE_COUNT")
dev_cmd_err_cnt = tlm("EPS EPS_HK_TLM DEVICE_ERR_COUNT")

# Test with Sample Switch Disabled
in_sun = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA IN_SUN")
get_eps_hk()
initial_batt_voltage = tlm("EPS EPS_HK_TLM BATT_VOLTAGE")

cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE OFF")
# Should charge during daytime and discharge at night with ambient power draw
if(in_sun != 0)
    wait_check("EPS EPS_HK_TLM BATT_VOLTAGE >= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
else
    wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
end

# Test with Sample Switch Enabled
cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE ON")
in_sun = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA IN_SUN")
get_eps_hk()
initial_batt_voltage = tlm("EPS EPS_HK_TLM BATT_VOLTAGE")

#Always draws more power than is being put in if Sample is enabled
if(in_sun != 0)
    wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
else
    wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
end
cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE OFF")

get_eps_hk()
check("EPS EPS_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
check("EPS EPS_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_7, STATE ON")


cmd("MGR MGR_SET_AK_CC with AK_STATUS ENABLE")
cmd("MGR MGR_SET_CONUS_CC with CONUS_STATUS ENABLE")
cmd("MGR MGR_SET_HI_CC with HI_STATUS ENABLE")
sleep(EPS_CMD_SLEEP)
cmd("MGR MGR_SET_MODE_CC with SPACECRAFT_MODE SCIENCE")