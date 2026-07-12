# Library for ADCS Target
require 'cosmos'
require 'cosmos/script'
require 'generic_css_lib.rb'
require 'generic_fss_lib.rb'
require 'generic_imu_lib.rb'
require 'generic_mag_lib.rb'
require 'generic_reaction_wheel_lib.rb'
require 'generic_st_lib.rb'
require 'gps_lib.rb'

#
# Definitions
#
ADCS_CMD_SLEEP = 0.25
ADCS_RESPONSE_TIMEOUT = 5
ADCS_MODE_CHECK_TIMEOUT = 60;
ADCS_TEST_LOOP_COUNT = 1
ADCS_DEVICE_LOOP_COUNT = 5

#
# Functions
#
def get_adcs_hk()
    cmd("ADCS ADCS_REQ_HK")
    wait_check_packet("ADCS", "ADCS_HK_TLM", 1, ADCS_RESPONSE_TIMEOUT)
    sleep(ADCS_CMD_SLEEP)
end

def get_adcs_data()
    cmd("ADCS ADCS_SEND_DI_CC")
    wait_check_packet("ADCS", "ADCS_DI", 1, ADCS_RESPONSE_TIMEOUT)
    cmd("ADCS ADCS_SEND_GNC_CC")
    wait_check_packet("ADCS", "ADCS_GNC", 1, ADCS_RESPONSE_TIMEOUT)
    cmd("ADCS ADCS_SEND_AD_CC")
    wait_check_packet("ADCS", "ADCS_AD", 1, ADCS_RESPONSE_TIMEOUT)
    cmd("ADCS ADCS_SEND_AC_CC")
    wait_check_packet("ADCS", "ADCS_AC", 1, ADCS_RESPONSE_TIMEOUT)
    cmd("ADCS ADCS_SEND_DO_CC")
    wait_check_packet("ADCS", "ADCS_DO", 1, ADCS_RESPONSE_TIMEOUT)
    sleep(ADCS_CMD_SLEEP)
end

def adcs_cmd(*command)
    count = tlm("ADCS ADCS_HK_TLM CMD_COUNT") + 1

    if (count == 256)
        count = 0
    end

    cmd(*command)
    get_adcs_hk()
    current = tlm("ADCS ADCS_HK_TLM CMD_COUNT")
    if (current != count)
        # Try again
        cmd(*command)
        get_adcs_hk()
        current = tlm("ADCS ADCS_HK_TLM CMD_COUNT")
        if (current != count)
            # Third times the charm
            cmd(*command)
            get_adcs_hk()
            current = tlm("ADCS ADCS_HK_TLM CMD_COUNT")
        end
    end
    check("ADCS ADCS_HK_TLM CMD_COUNT >= #{count}")
end

def adcs_sunsafe()

    cmd("ADCS ADCS_SET_MODE_CC with GNC_MODE SUNSAFE_MODE")

end

def adcs_bdot()

    cmd("ADCS ADCS_SET_MODE_CC with GNC_MODE BDOT_MODE")

end

def adcs_inertial()

    cmd("ADCS ADCS_SET_MODE_CC with GNC_MODE INERTIAL_MODE")

end

def adcs_passive()

    cmd("ADCS ADCS_SET_MODE_CC with GNC_MODE PASSIVE")

end

def adcs_set_q()

    cmd("ADCS ADCS_INERTIAL_QUATERNION_CC with GNC_INER_QUAT1 0.0, GNC_INER_QUAT2 0.0, GNC_INER_QUAT3 0.0, GNC_INER_QUAT4 1.0")

end

def safe_adcs()

    cmd("FSS FSS_REQ_HK")
    fss_enabled = tlm("FSS FSS_HK_TLM DEVICE_ENABLED")
    if (fss_enabled != "ENABLED")
        cmd("FSS FSS_ENABLE_CC")
    end

    cmd("CSS CSS_REQ_HK")
    css_enabled = tlm("CSS CSS_HK_TLM DEVICE_ENABLED")
    if (css_enabled != "ENABLED")
        cmd("CSS CSS_ENABLE_CC")
    end

    cmd("IMU IMU_REQ_HK")
    imu_enabled = tlm("IMU IMU_HK_TLM DEVICE_ENABLED")
    if (imu_enabled != "ENABLED")
        cmd("IMU IMU_ENABLE_CC")
    end

    cmd("MAG MAG_REQ_HK")
    mag_enabled = tlm("MAG MAG_HK_TLM DEVICE_ENABLED")
    if (mag_enabled != "ENABLED")
        cmd("MAG MAG_ENABLE_CC")
    end

    sw1_state = tlm("EPS EPS_HK_TLM SWITCH_1_STATE")
    if(sw1_state == "OFF")
        eps_cmd("EPS EPS_SWITCH_CC with SWITCH_NUMBER SWITCH_1, STATE ON")
    end

    cmd("STAR_TRACKER STAR_TRACKER_REQ_HK")
    st_enabled = tlm("STAR_TRACKER STAR_TRACKER_HK_TLM DEVICE_ENABLED")
    if (st_enabled != "ENABLED")
        cmd("STAR_TRACKER STAR_TRACKER_ENABLE_CC")
    end

    cmd("NOVATEL_OEM615 NOVATEL_OEM615_REQ_HK")
    gps_enabled = tlm("NOVATEL_OEM615 NOVATEL_OEM615_HK_TLM DEVICE_ENABLED")
    if (gps_enabled != "ENABLED")
        cmd("NOVATEL_OEM615 NOVATEL_OEM615_ENABLE_CC")
    end

    cmd("TORQUER TORQUER_REQ_HK_CC")
    torquer_enabled = tlm("TORQUER TORQUER_HK_TLM_T DEVICE_ENABLED")
    if (torquer_enabled != "ENABLED")
        cmd("TORQUER TORQUER_ENABLE_CC")
    end

    get_adcs_data()
    mode = tlm("ADCS ADCS_GNC MODE")
    if (mode != "SUNSAFE")
        adcs_sunsafe()
    end
end

def confirm_adcs_data()
    
    adcs_sunsafe()

    diff = 0.05

    get_adcs_data()
    adcs_sun_valid = tlm("ADCS ADCS_GNC SUN_VALID")
    if adcs_sun_valid == 0
        wait_check_tolerance("ADCS ADCS_GNC SVB_X", 1.0, diff, ADCS_MODE_CHECK_TIMEOUT)
        wait_check_tolerance("ADCS ADCS_GNC SVB_Y", 0.0, diff, ADCS_MODE_CHECK_TIMEOUT)
        wait_check_tolerance("ADCS ADCS_GNC SVB_Z", 0.0, diff, ADCS_MODE_CHECK_TIMEOUT)

        diff = 50
        wait_check_tolerance("ADCS ADCS_GNC CSS_0", 1000, diff, ADCS_MODE_CHECK_TIMEOUT)
    end

    cmd("IMU IMU_REQ_DATA")

    x_ang_rate_before = tlm("IMU IMU_DATA_TLM X_ANGULAR_RATE").abs
    y_ang_rate_before = tlm("IMU IMU_DATA_TLM Y_ANGULAR_RATE").abs
    z_ang_rate_before = tlm("IMU IMU_DATA_TLM Z_ANGULAR_RATE").abs

    adcs_bdot()

    diff = 0.05
    
    wait_check("IMU IMU_DATA_TLM X_ANGULAR_RATE < #{x_ang_rate_before}", ADCS_MODE_CHECK_TIMEOUT)
    wait_check("IMU IMU_DATA_TLM Y_ANGULAR_RATE < #{y_ang_rate_before}", ADCS_MODE_CHECK_TIMEOUT)
    wait_check("IMU IMU_DATA_TLM Z_ANGULAR_RATE < #{z_ang_rate_before}", ADCS_MODE_CHECK_TIMEOUT)

    adcs_inertial()
    adcs_set_q();

    sleep(ADCS_MODE_CHECK_TIMEOUT)

    qbn0 = tlm("ADCS ADCS_GNC QBN_0").abs
    qbn1 = tlm("ADCS ADCS_GNC QBN_1").abs
    qbn2 = tlm("ADCS ADCS_GNC QBN_2").abs
    qbn3 = tlm("ADCS ADCS_GNC QBN_3").abs

    wait_check_expression("#{qbn0} < 0.1", ADCS_MODE_CHECK_TIMEOUT)
    wait_check_expression("#{qbn1} < 0.1", ADCS_MODE_CHECK_TIMEOUT)
    wait_check_expression("#{qbn2} < 0.1", ADCS_MODE_CHECK_TIMEOUT)
    wait_check_expression("#{qbn3} > 0.9", ADCS_MODE_CHECK_TIMEOUT)

    get_adcs_hk()
end

def adcs_confirm_css_data()

    dev_cmd_cnt = tlm("CSS CSS_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("CSS CSS_HK_TLM DEVICE_ERR_COUNT")

    diff = 0.05
    
    # Note these checks assume truth data from 42 is available, and that the spacecraft is not rapidly tumbling
    # The CSS orientations were taken from the ./cfg/InOut/SC_NOS3.txt
    in_sun = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA IN_SUN")
    if(in_sun > 0)
        # CSS 0,  1, 0, 0
        svb_0 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_0")
        get_generic_css_data()
        get_adcs_data()
        if(svb_0 > 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_0", svb_0 * 1000, CSS_DEVICE_TRUTH_MARGIN)
            css0_val = tlm("CSS CSS_DATA_TLM RAW_CSS_0")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON0", css0_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_0", 0, CSS_DEVICE_TRUTH_MARGIN)
            css0_val = tlm("CSS CSS_DATA_TLM RAW_CSS_0")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON0", css0_val, diff)
        end

        # CSS 1, -1, 0, 0
        svb_0 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_0")
        get_generic_css_data()
        get_adcs_data()
        if(svb_0 < 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_1", svb_0 * -1000, CSS_DEVICE_TRUTH_MARGIN)
            css1_val = tlm("CSS CSS_DATA_TLM RAW_CSS_1")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON1", css1_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_1", 0, CSS_DEVICE_TRUTH_MARGIN)
            css1_val = tlm("CSS CSS_DATA_TLM RAW_CSS_1")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON1", css1_val, diff)
        end

        # CSS 2,  0, 1, 0
        svb_1 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_1")
        get_generic_css_data()
        get_adcs_data()
        if(svb_1 > 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_2", svb_1 * 1000, CSS_DEVICE_TRUTH_MARGIN)
            css2_val = tlm("CSS CSS_DATA_TLM RAW_CSS_2")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON2", css2_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_2", 0, CSS_DEVICE_TRUTH_MARGIN)
            css2_val = tlm("CSS CSS_DATA_TLM RAW_CSS_2")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON2", css2_val, diff)
        end

        # CSS 3,  0,-1, 0
        svb_1 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_1")
        get_generic_css_data()
        get_adcs_data()
        if(svb_1 < 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_3", svb_1 * -1000, CSS_DEVICE_TRUTH_MARGIN)
            css3_val = tlm("CSS CSS_DATA_TLM RAW_CSS_3")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON3", css3_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_3", 0, CSS_DEVICE_TRUTH_MARGIN)
            css3_val = tlm("CSS CSS_DATA_TLM RAW_CSS_3")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON3", css3_val, diff)
        end

        # CSS 4,  0, 0, 1
        svb_2 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_2")
        get_generic_css_data()
        get_adcs_data()
        if(svb_2 > 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_4", svb_2 * 1000, CSS_DEVICE_TRUTH_MARGIN)
            css4_val = tlm("CSS CSS_DATA_TLM RAW_CSS_4")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON4", css4_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_4", 0, CSS_DEVICE_TRUTH_MARGIN)
            css4_val = tlm("CSS CSS_DATA_TLM RAW_CSS_4")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON4", css4_val, diff)
        end

        # CSS 5,  0, 0,-1
        svb_2 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_2")
        get_generic_css_data()
        get_adcs_data()
        if(svb_2 < 0)
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_5", svb_2 * -1000, CSS_DEVICE_TRUTH_MARGIN)
            css5_val = tlm("CSS CSS_DATA_TLM RAW_CSS_5")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON5", css5_val, diff)
        else
            check_tolerance("CSS CSS_DATA_TLM RAW_CSS_5", 0, CSS_DEVICE_TRUTH_MARGIN)
            css5_val = tlm("CSS CSS_DATA_TLM RAW_CSS_5")/1000.0
            check_tolerance("ADCS ADCS_DI PERCENTON5", css5_val, diff)
        end
    end
end

def adcs_confirm_fss_data()
    
    dev_cmd_cnt = tlm("FSS FSS_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("FSS FSS_HK_TLM DEVICE_ERR_COUNT")
    
    get_fss_data()
    get_adcs_data()
    truth_svb0 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_0")
    truth_svb1 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_1")
    truth_svb2 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA SVB_2")

    adcs_svb0 = tlm("ADCS ADCS_DI FSS_SVB_X")
    adcs_svb1 = tlm("ADCS ADCS_DI FSS_SVB_Y")
    adcs_svb2 = tlm("ADCS ADCS_DI FSS_SVB_Z")

    fss_error = tlm("FSS FSS_DATA_TLM FSS_ERROR_CODE")

    wait_check("ADCS ADCS_DI FSS_VALID == 1", ADCS_MODE_CHECK_TIMEOUT)

    truth_42_alpha = -Math.atan2(truth_svb2, truth_svb0)
    truth_42_beta = Math.atan2(truth_svb1, truth_svb0)

    adcs_alpha = -Math.atan2(adcs_svb2, adcs_svb0)
    adcs_beta = Math.atan2(adcs_svb1, adcs_svb0)

    diff = 0.03

    if fss_error == 0
        wait_check_tolerance("FSS FSS_DATA_TLM FSS_ALPHA", truth_42_alpha, diff, FSS_RESPONSE_TIMEOUT)

        wait_check_tolerance("FSS FSS_DATA_TLM FSS_ALPHA", adcs_alpha, diff, FSS_RESPONSE_TIMEOUT)

        wait_check_tolerance("FSS FSS_DATA_TLM FSS_BETA", truth_42_beta, diff, FSS_RESPONSE_TIMEOUT)

        wait_check_tolerance("FSS FSS_DATA_TLM FSS_BETA", adcs_beta, diff, FSS_RESPONSE_TIMEOUT)
    end

    get_fss_hk()
    check("FSS FSS_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
    check("FSS FSS_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
    
end

def adcs_confirm_imu_data()
    
    dev_cmd_cnt = tlm("IMU IMU_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("IMU IMU_HK_TLM DEVICE_ERR_COUNT")
    
    get_generic_imu_data()
    get_adcs_data()
    # Note these checks assume default simulator configuration

    # X Axis Angular
    truth_42_GYRO_X = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA GYRO_B_X")
    check_tolerance("IMU IMU_DATA_TLM X_ANGULAR_RATE", truth_42_GYRO_X, IMU_DEVICE_ANGULAR_DIFF)
    adcs_GYRO_X = tlm("ADCS ADCS_DI IMU_WBN_X")
    check_tolerance("IMU IMU_DATA_TLM X_ANGULAR_RATE", adcs_GYRO_X, IMU_DEVICE_ANGULAR_DIFF)

    # Y Axis Angular
    truth_42_GYRO_Y = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA GYRO_B_Y")
    check_tolerance("IMU IMU_DATA_TLM Y_ANGULAR_RATE", truth_42_GYRO_Y, IMU_DEVICE_ANGULAR_DIFF)
    adcs_GYRO_Y = tlm("ADCS ADCS_DI IMU_WBN_Y")
    check_tolerance("IMU IMU_DATA_TLM Y_ANGULAR_RATE", adcs_GYRO_Y, IMU_DEVICE_ANGULAR_DIFF)

    # Z Axis Angular
    truth_42_GYRO_Z = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA GYRO_B_Z")
    check_tolerance("IMU IMU_DATA_TLM Z_ANGULAR_RATE", truth_42_GYRO_Z, IMU_DEVICE_ANGULAR_DIFF)
    adcs_GYRO_Z = tlm("ADCS ADCS_DI IMU_WBN_Z")
    check_tolerance("IMU IMU_DATA_TLM Z_ANGULAR_RATE", adcs_GYRO_Z, IMU_DEVICE_ANGULAR_DIFF)

    # X Axis Linear
    truth_42_ACC_X = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA ACC_B_X")
    check_tolerance("IMU IMU_DATA_TLM X_LINEAR_ACCELERATION", truth_42_ACC_X, IMU_DEVICE_LINEAR_DIFF)
    adcs_ACC_X = tlm("ADCS ADCS_DI IMU_ACC_X")
    check_tolerance("IMU IMU_DATA_TLM X_LINEAR_ACCELERATION", adcs_ACC_X, IMU_DEVICE_LINEAR_DIFF)

    # Y Axis Linear
    truth_42_ACC_Y = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA ACC_B_Y")
    check_tolerance("IMU IMU_DATA_TLM Y_LINEAR_ACCELERATION", truth_42_ACC_Y, IMU_DEVICE_LINEAR_DIFF)
    adcs_ACC_Y = tlm("ADCS ADCS_DI IMU_ACC_Y")
    check_tolerance("IMU IMU_DATA_TLM Y_LINEAR_ACCELERATION", adcs_ACC_Y, IMU_DEVICE_LINEAR_DIFF)

    # Z Axis Linear
    truth_42_ACC_Z = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA ACC_B_Z")
    check_tolerance("IMU IMU_DATA_TLM Z_LINEAR_ACCELERATION", truth_42_ACC_Z, IMU_DEVICE_LINEAR_DIFF)
    adcs_ACC_Z = tlm("ADCS ADCS_DI IMU_ACC_Z")
    check_tolerance("IMU IMU_DATA_TLM Z_LINEAR_ACCELERATION", adcs_ACC_Z, IMU_DEVICE_LINEAR_DIFF)

    get_generic_imu_hk()
    check("IMU IMU_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
    check("IMU IMU_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
    
end

def adcs_confirm_mag_data()
    
    dev_cmd_cnt = tlm("MAG MAG_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("MAG MAG_HK_TLM DEVICE_ERR_COUNT")
    
    
    # Note these checks assume default simulator configuration
    truth_42_bvb0 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA BVB_X_NT")
    get_generic_mag_data()
    get_adcs_data()
    check_tolerance("MAG MAG_DATA_TLM RAW_MAG_X", truth_42_bvb0, MAG_DEVICE_NT_DIFFERENCE)
    adcs_bvb0 = tlm("ADCS ADCS_DI BVB_X")
    wait_check_tolerance("MAG MAG_DATA_TLM RAW_MAG_X", adcs_bvb0 * 1000000000, MAG_DEVICE_NT_DIFFERENCE, ADCS_RESPONSE_TIMEOUT)


    truth_42_bvb1 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA BVB_Y_NT")
    get_generic_mag_data()
    get_adcs_data()
    check_tolerance("MAG MAG_DATA_TLM RAW_MAG_Y", truth_42_bvb1, MAG_DEVICE_NT_DIFFERENCE)
    adcs_bvb1 = tlm("ADCS ADCS_DI BVB_Y")
    wait_check_tolerance("MAG MAG_DATA_TLM RAW_MAG_Y", adcs_bvb1 * 1000000000, MAG_DEVICE_NT_DIFFERENCE, ADCS_RESPONSE_TIMEOUT)

    truth_42_bvb2 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA BVB_Z_NT")
    get_generic_mag_data()
    get_adcs_data()
    check_tolerance("MAG MAG_DATA_TLM RAW_MAG_Z", truth_42_bvb2, MAG_DEVICE_NT_DIFFERENCE)
    adcs_bvb2 = tlm("ADCS ADCS_DI BVB_Z")
    wait_check_tolerance("MAG MAG_DATA_TLM RAW_MAG_Z", adcs_bvb2 * 1000000000, MAG_DEVICE_NT_DIFFERENCE, ADCS_RESPONSE_TIMEOUT)

    get_generic_mag_hk()
    check("MAG MAG_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
    check("MAG MAG_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
    
end

def adcs_confirm_rw_data()

    diff = 0.05

    get_adcs_data()
    get_REACTION_WHEEL_data()
    adcs_rw0 = tlm("ADCS ADCS_DO TCMD_X")
    wait_check_tolerance("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_0", adcs_rw0, diff, ADCS_MODE_CHECK_TIMEOUT)

    get_adcs_data()
    get_REACTION_WHEEL_data()
    adcs_rw1 = tlm("ADCS ADCS_DO TCMD_Y")
    wait_check_tolerance("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_1", adcs_rw1, diff, ADCS_MODE_CHECK_TIMEOUT)

    get_adcs_data()
    get_REACTION_WHEEL_data()
    adcs_rw2 = tlm("ADCS ADCS_DO TCMD_Z")
    wait_check_tolerance("REACTION_WHEEL GENRW_HK_TLM_T MOMENTUM_NMS_2", adcs_rw2, diff, ADCS_MODE_CHECK_TIMEOUT)

end

def adcs_confirm_st_data()
    
    dev_cmd_cnt = tlm("STAR_TRACKER STAR_TRACKER_HK_TLM DEVICE_COUNT")
    dev_cmd_err_cnt = tlm("STAR_TRACKER STAR_TRACKER_HK_TLM DEVICE_ERR_COUNT")
    
    get_generic_star_tracker_data()
    get_adcs_data()
    # Note these checks assume default simulator configuration
    diff = 0.05
    #Todo check values with lower margin
    #Margin is large, testing that Q values not equal to 0

    #Checking Q0
    st_Q0 = tlm("STAR_TRACKER STAR_TRACKER_DATA_TLM STAR_TRACKER_Q0").abs
    sim42_Q0 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA QN_0").abs
    adcs_Q0 = tlm("ADCS ADCS_DI ST_Q_0").abs
    puts "sim42_q0 is #{sim42_Q0}"
    puts "adcs_q0 is #{adcs_Q0}"
    puts "st_q0 is #{st_Q0}"

    wait_check_expression("#{st_Q0} < #{sim42_Q0 + 0.05} or #{st_Q0} > #{sim42_Q0 - 0.05}", 30)
    wait_check_expression("#{st_Q0} < #{adcs_Q0 + 0.05} or #{st_Q0} > #{adcs_Q0 - 0.05}", 30)

    #Checking Q1
    st_Q1 = tlm("STAR_TRACKER STAR_TRACKER_DATA_TLM STAR_TRACKER_Q1").abs
    sim42_Q1 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA QN_1").abs
    adcs_Q1 = tlm("ADCS ADCS_DI ST_Q_1").abs
    puts "sim42_q1 is #{sim42_Q1}"
    puts "adcs_q1 is #{adcs_Q1}"
    puts "st_q1 is #{st_Q1}"

    wait_check_expression("#{st_Q1} < #{sim42_Q1 + 0.05} or #{st_Q1} > #{sim42_Q1 - 0.05}", 30)
    wait_check_expression("#{st_Q1} < #{adcs_Q1 + 0.05} or #{st_Q1} > #{adcs_Q1 - 0.05}", 30)

    #Checking Q2
    st_Q2 = tlm("STAR_TRACKER STAR_TRACKER_DATA_TLM STAR_TRACKER_Q2").abs
    sim42_Q2 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA QN_2").abs
    adcs_Q2 = tlm("ADCS ADCS_DI ST_Q_2").abs
    puts "sim42_q2 is #{sim42_Q2}"
    puts "adcs_q2 is #{adcs_Q2}"
    puts "st_q2 is #{st_Q2}"

    wait_check_expression("#{st_Q2} < #{sim42_Q2 + 0.05} or #{st_Q2} > #{sim42_Q2 - 0.05}", 30)
    wait_check_expression("#{st_Q2} < #{adcs_Q2 + 0.05} or #{st_Q2} > #{adcs_Q2 - 0.05}", 30)


    #Checking Q3
    st_Q3 = tlm("STAR_TRACKER STAR_TRACKER_DATA_TLM STAR_TRACKER_Q3").abs
    sim42_Q3 = tlm("SIM_42_TRUTH SIM_42_TRUTH_DATA QN_3").abs
    adcs_Q3 = tlm("ADCS ADCS_DI ST_Q_3").abs
    puts "sim42_q3 is #{sim42_Q3}"
    puts "adcs_q3 is #{adcs_Q3}"
    puts "st_q3 is #{st_Q3}"

    wait_check_expression("#{st_Q3} < #{sim42_Q3 + 0.05} or #{st_Q3} > #{sim42_Q3 - 0.05}", 30)
    wait_check_expression("#{st_Q3} < #{adcs_Q3 + 0.05} or #{st_Q3} > #{adcs_Q3 - 0.05}", 30)



    get_generic_star_tracker_hk()
    check("STAR_TRACKER STAR_TRACKER_HK_TLM DEVICE_COUNT >= #{dev_cmd_cnt}")
    check("STAR_TRACKER STAR_TRACKER_HK_TLM DEVICE_ERR_COUNT == #{dev_cmd_err_cnt}")
    
end

def confirm_adcs_data_loop()
    ADCS_DEVICE_LOOP_COUNT.times do |n|
        confirm_adcs_data()
    end
end
