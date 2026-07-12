# Library for REACTION_WHEEL Target
require 'cosmos'
require 'cosmos/script'

#
# Definitions
#
REACTION_WHEEL_CMD_SLEEP = 0.25
REACTION_WHEEL_RESPONSE_TIMEOUT = 10
REACTION_WHEEL_TORQUE_RESPONSE_SLEEP = 3
REACTION_WHEEL_TEST_LOOP_COUNT = 1
REACTION_WHEEL_DEVICE_LOOP_COUNT = 1
REACTION_WHEEL_MAX_MOMENTUM_NM = 0.01

#
# Functions
#
def get_REACTION_WHEEL_data()
    cmd("REACTION_WHEEL RW_REQ_DATA_CC")
    wait_check_packet("REACTION_WHEEL", "GENRW_HK_TLM_T", 1, REACTION_WHEEL_RESPONSE_TIMEOUT)
    sleep(REACTION_WHEEL_CMD_SLEEP)
end

def REACTION_WHEEL_cmd(*command)
    count = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT") + 1

    if (count == 256)
        count = 0
    end

    cmd(*command)
    get_REACTION_WHEEL_data()
    current = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
    if (current != count)
        # Try again
        cmd(*command)
        get_REACTION_WHEEL_data()
        current = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
        if (current != count)
            # Third times the charm
            cmd(*command)
            get_REACTION_WHEEL_data()
            current = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
        end
    end
    check("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT >= #{count}")
end

def turn_off_RWS
    #Turning off RW's
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE 0")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE 0")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE 0")
end


def safe_REACTION_WHEEL()
    get_REACTION_WHEEL_data()
    #Turn off RWs, set to 0
    turn_off_RWS()
end

def confirm_REACTION_WHEEL_data()
    cmd_err_cnt = tlm("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT")
       
    # Checking RW 0 Positive Direction
    rw0_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE 10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw0_momentum_init >= REACTION_WHEEL_MAX_MOMENTUM_NM)
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0 >= #{rw0_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0 > #{rw0_momentum_init}")
    end
    rw0_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0")
    puts "Reaction Wheel 0 Momentum (N m): #{rw0_momentum}"
    
    # Checking RW 1 Positive Direction
    rw1_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE 10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw1_momentum_init >= REACTION_WHEEL_MAX_MOMENTUM_NM)
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1 >= #{rw1_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1 > #{rw1_momentum_init}")
    end
    rw1_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1")
    puts "Reaction Wheel 1 Momentum (N m): #{rw1_momentum}"
     
    # Checking RW 2 Positive Direction
    rw2_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE 10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw2_momentum_init >= REACTION_WHEEL_MAX_MOMENTUM_NM)
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2 >= #{rw2_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2 > #{rw2_momentum_init}")
    end
    rw2_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2")
    puts "Reaction Wheel 2 Momentum (N m): #{rw2_momentum}"

    # Checking RW 0 Negative Direction
    rw0_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE -10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw0_momentum_init <= (-1 * REACTION_WHEEL_MAX_MOMENTUM_NM))
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0 <= #{rw0_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0 < #{rw0_momentum_init}")
    end
    rw0_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0")
    puts "Reaction Wheel 0 Momentum (N m): #{rw0_momentum}"
    
    # Checking RW 1 Negative Direction
    rw1_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE -10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw1_momentum_init <= (-1 * REACTION_WHEEL_MAX_MOMENTUM_NM))
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1 <= #{rw1_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1 < #{rw1_momentum_init}")
    end
    rw1_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1")
    puts "Reaction Wheel 1 Momentum (N m): #{rw1_momentum}"
        
    # Checking RW 2 Negative Direction
    rw2_momentum_init = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2")
    REACTION_WHEEL_cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE -10")
    sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP
    get_REACTION_WHEEL_data()
    if (rw2_momentum_init <= (-1 * REACTION_WHEEL_MAX_MOMENTUM_NM))
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2 <= #{rw2_momentum_init}")
    else
        check("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2 < #{rw2_momentum_init}")
    end
    rw2_momentum = tlm("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2")
    puts "Reaction Wheel 2 Momentum (N m): #{rw2_momentum}"

    # Confirm no errors
    get_REACTION_WHEEL_data()
    check("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT == #{cmd_err_cnt}")
end

def confirm_REACTION_WHEEL_data_loop()
    REACTION_WHEEL_DEVICE_LOOP_COUNT.times do |n|
        confirm_REACTION_WHEEL_data()
    end
end

def confirm_RW_device_data()
    dev_cnt_rw0 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW0")
    dev_cnt_rw1 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW1")
    dev_cnt_rw2 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW2")

    dev_err_cnt_RW0 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0")
    dev_err_cnt_RW1 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW1")
    dev_err_cnt_RW2 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW2")

    turn_off_RWS()

    get_REACTION_WHEEL_data()

    #RW0
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW0 >= #{dev_cnt_rw0}")
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0 == #{dev_err_cnt_RW0}")

    #RW1
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW1 >= #{dev_cnt_rw1}")
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0 == #{dev_err_cnt_RW1}")

    #RW2
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_COUNT_RW2 >= #{dev_cnt_rw2}")
    check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0 == #{dev_err_cnt_RW2}")
end

def get_REACTION_WHEEL_data_loop()
    REACTION_WHEEL_DEVICE_LOOP_COUNT.times do |n|
        get_REACTION_WHEEL_data()
    end
end

def teardown_RW
    turn_off_RWS()
end

def enable_all_RW()
    cmd("REACTION_WHEEL RW_ENABLE_CC with WHEEL_NUMBER 0")
    cmd("REACTION_WHEEL RW_ENABLE_CC with WHEEL_NUMBER 1")
    cmd("REACTION_WHEEL RW_ENABLE_CC with WHEEL_NUMBER 2")
end

def disable_all_RW()

    cmd("REACTION_WHEEL RW_DISABLE_CC with WHEEL_NUMBER 0")
    cmd("REACTION_WHEEL RW_DISABLE_CC with WHEEL_NUMBER 1")
    cmd("REACTION_WHEEL RW_DISABLE_CC with WHEEL_NUMBER 2")
end

def generic_rw0_sim_disable()
    cmd("SIM_CMDBUS_BRIDGE RW0_DISABLE")
end

def generic_rw1_sim_disable()
    cmd("SIM_CMDBUS_BRIDGE RW1_DISABLE")
end

def generic_rw2_sim_disable()
    cmd("SIM_CMDBUS_BRIDGE RW2_DISABLE")
end


def generic_rw0_sim_enable()
    cmd("SIM_CMDBUS_BRIDGE RW0_ENABLE")
end

def generic_rw1_sim_enable()
    cmd("SIM_CMDBUS_BRIDGE RW1_ENABLE")
end

def generic_rw2_sim_enable()
    cmd("SIM_CMDBUS_BRIDGE RW2_ENABLE")
end

#
# Simulator Functions
#
def REACTION_WHEEL_prepare_ast()
    # Get to known state
    safe_REACTION_WHEEL()

    # Confirm data
    confirm_REACTION_WHEEL_data()

    teardown_RW()
end

