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

def eps_cmd(*command)
    count = tlm("EPS EPS_HK_TLM CMD_COUNT") + 1

    if (count == 256)
        count = 0
    end

    cmd(*command)
    get_eps_hk()
    current = tlm("EPS EPS_HK_TLM CMD_COUNT")
    if (current != count)
        # Try again
        cmd(*command)
        get_eps_hk()
        current = tlm("EPS EPS_HK_TLM CMD_COUNT")
        if (current != count)
            # Third times the charm
            cmd(*command)
            get_eps_hk()
            current = tlm("EPS EPS_HK_TLM CMD_COUNT")
        end
    end
    check("EPS EPS_HK_TLM CMD_COUNT >= #{count}")
end

def safe_eps()
    get_eps_hk()
    sw0_state = tlm("EPS EPS_HK_TLM SWITCH_0_STATE")
    sw1_state = tlm("EPS EPS_HK_TLM SWITCH_1_STATE")
    sw2_state = tlm("EPS EPS_HK_TLM SWITCH_2_STATE")
    sw3_state = tlm("EPS EPS_HK_TLM SWITCH_3_STATE")
    sw4_state = tlm("EPS EPS_HK_TLM SWITCH_4_STATE")
    sw5_state = tlm("EPS EPS_HK_TLM SWITCH_5_STATE")
    sw6_state = tlm("EPS EPS_HK_TLM SWITCH_6_STATE")
    sw7_state = tlm("EPS EPS_HK_TLM SWITCH_7_STATE")

    if(sw0_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE OFF")
    end
    if(sw1_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_1, STATE OFF")
    end
    if(sw2_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_2, STATE OFF")
    end
    if(sw3_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_3, STATE OFF")
    end
    if(sw4_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_4, STATE OFF")
    end
    if(sw5_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_5, STATE OFF")
    end
    if(sw6_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_6, STATE OFF")
    end
    if(sw7_state == "ON")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_7, STATE OFF")
    end

end

def confirm_eps_data()
    dev_cmd_cnt = tlm("EPS EPS_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("EPS EPS_HK_TLM DEVICE_ERR_COUNT")

    # Test with Sample Switch Disabled
    in_sun = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA IN_SUN")
    get_eps_hk()
    initial_batt_voltage = tlm("EPS EPS_HK_TLM BATT_VOLTAGE")

    eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE OFF")
    # Should charge during daytime and discharge at night with ambient power draw
    if(in_sun != 0)
        wait_check("EPS EPS_HK_TLM BATT_VOLTAGE >= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
    else
        wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
    end

    # Test with Sample Switch Enabled
    eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE ON")
    in_sun = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA IN_SUN")
    get_eps_hk()
    initial_batt_voltage = tlm("EPS EPS_HK_TLM BATT_VOLTAGE")

    #Always draws more power than is being put in if Sample is enabled
    if(in_sun != 0)
        wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
    else
        wait_check("EPS EPS_HK_TLM BATT_VOLTAGE <= #{initial_batt_voltage}", EPS_RESPONSE_TIMEOUT)
    end
    eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_0, STATE OFF")

    get_eps_hk()
    check("EPS EPS_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
    check("EPS EPS_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
end

def confirm_eps_data_loop()
    EPS_DEVICE_LOOP_COUNT.times do |n|
        confirm_eps_data()
    end
end

#
# Simulator Functions
#
def eps_prepare_ast()
    # Get to known state
    safe_eps()

    # Confirm data
    confirm_eps_data_loop()
end

def eps_sim_enable()
    cmd("SIM_CMDBUS_BRIDGE EPS_SIM_ENABLE")
end

def eps_sim_disable()
    cmd("SIM_CMDBUS_BRIDGE EPS_SIM_DISABLE")
end

def eps_sim_set_status(status)
    cmd("SIM_CMDBUS_BRIDGE EPS_SIM_SET_STATUS with STATUS #{status}")
end
