require 'cosmos'
require 'cosmos/script'
require "generic_reaction_wheel_lib.rb"

##
## Hardware failure
##

REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
  # Prepare
  REACTION_WHEEL_prepare_ast()

  cmd_cnt = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
  cmd_err_cnt = tlm("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT")
  dev_err_cnt_RW0 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0")
  dev_err_cnt_RW1 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW1")
  dev_err_cnt_RW2 = tlm("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW2")

  generic_rw0_sim_disable()
  generic_rw1_sim_disable()
  generic_rw2_sim_disable()

  # 3 RW commands, 1 for each wheel
  cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 0, TORQUE 0")
  cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 1, TORQUE 0")
  cmd("REACTION_WHEEL RW_SET_TORQUE_CC with WHEEL_NUMBER 2, TORQUE 0")

  get_REACTION_WHEEL_data()
  check("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT  == #{cmd_cnt}")
  check("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT >= #{cmd_err_cnt}")
  check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW0 >= #{dev_err_cnt_RW0}")
  check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW1 >= #{dev_err_cnt_RW1}")
  check("REACTION_WHEEL GENRW_HK_TLM_T DEVICE_ERR_COUNT_RW2 >= #{dev_err_cnt_RW2}")

  generic_rw0_sim_enable()
  generic_rw1_sim_enable()
  generic_rw2_sim_enable()
  sleep REACTION_WHEEL_TORQUE_RESPONSE_SLEEP

  confirm_REACTION_WHEEL_data()
end 

puts "End of RW AST Test Script"
