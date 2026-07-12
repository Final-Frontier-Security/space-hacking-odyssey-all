# Library for RADIO Target
require 'cosmos'
require 'cosmos/script'

#
# Definitions
#
RADIO_CMD_SLEEP = 0.25
RADIO_RESPONSE_TIMEOUT = 5
RADIO_TEST_LOOP_COUNT = 1
RADIO_DEVICE_LOOP_COUNT = 1


# cmd("RADIO RADIO_NOOP_CC")
# cmd("RADIO RADIO_CONFIG_CC with DEVICE_CONFIG 0")
# cmd("RADIO RADIO_CONFIG_CC with DEVICE_CONFIG 1")
# cmd("RADIO RADIO_PROXIMITY_CC with SCID 0, PROX_DATA 0x1930C00000010000")
# cmd("RADIO RADIO_PROXIMITY_CC with SCID 1, PROX_DATA 0x1930C00000010000")
# cmd("RADIO RADIO_RST_COUNTERS_CC")
# cmd("RADIO RADIO_REQ_HK")

#
# Functions
#
def get_RADIO_hk()
    cmd("RADIO RADIO_REQ_HK")
    wait_check_packet("RADIO", "RADIO_HK_TLM", 1, RADIO_RESPONSE_TIMEOUT)
    sleep(RADIO_CMD_SLEEP)
end


def RADIO_cmd(*command)
    count = tlm("RADIO RADIO_HK_TLM CMD_COUNT") + 1

    if (count == 256)
        count = 0
    end

    cmd(*command)
    get_RADIO_hk()
    current = tlm("RADIO RADIO_HK_TLM CMD_COUNT")
    if (current != count)
        # Try again
        cmd(*command)
        get_RADIO_hk()
        current = tlm("RADIO RADIO_HK_TLM CMD_COUNT")
        if (current != count)
            # Third times the charm
            cmd(*command)
            get_RADIO_hk()
            current = tlm("RADIO RADIO_HK_TLM CMD_COUNT")
        end
    end
    check("RADIO RADIO_HK_TLM CMD_COUNT >= #{count}")
end


def safe_RADIO()
    get_RADIO_hk()
end

def confirm_RADIO_data()
    dev_cmd_cnt = tlm("RADIO RADIO_HK_TLM DEVICE_COUNTER")
    dev_cmd_err_cnt = tlm("RADIO RADIO_HK_TLM DEVICE_ERR_COUNT")
    
    get_RADIO_hk()
    sleep 1
    check("RADIO RADIO_HK_TLM DEVICE_COUNTER >= #{dev_cmd_cnt}")
    check("RADIO RADIO_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
end

def confirm_RADIO_data_loop()
    RADIO_DEVICE_LOOP_COUNT.times do |n|
        confirm_RADIO_data()
    end
end

#
# Simulator Functions
#
def generic_radio_prepare_ast()
    # Get to known state
    safe_RADIO()

    # Confirm data
    confirm_RADIO_data_loop()
end

def generic_radio_sim_enable()
    cmd("SIM_CMDBUS_BRIDGE RADIO_SIM_ENABLE")
end

def generic_radio_sim_disable()
    cmd("SIM_CMDBUS_BRIDGE RADIO_SIM_DISABLE")
end
