require 'cosmos'
require 'cosmos/script'
require "generic_reaction_wheel_lib.rb"

##
# get tlm packet for Reaction wheel
##
REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
  get_REACTION_WHEEL_data()
end

##
## Confirm NOOP command
##
REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
  REACTION_WHEEL_cmd("REACTION_WHEEL RW_NOOP_CC")
end

##
## Confirm RW Data
## 
REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
  #Testing RW commands and detecting Momentum directions
  confirm_REACTION_WHEEL_data()
end

##
## reset counters
##
REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
  REACTION_WHEEL_cmd("REACTION_WHEEL RW_NOOP_CC")
  #ADCS May be running, so saving variables before reset
  initial_command_count = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
  initial_error_count = tlm("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT")

  cmd("REACTION_WHEEL RW_RST_COUNTERS_CC")

  get_REACTION_WHEEL_data()
  check("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT  < #{initial_command_count}")
  check("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT <= #{initial_error_count}")

end

##
##   Invalid ground command, confirm bad lengths and codes are rejected
##
REACTION_WHEEL_TEST_LOOP_COUNT.times do |n|
   REACTION_WHEEL_cmd("REACTION_WHEEL RW_NOOP_CC")
   # Bad length
   cmd_cnt = tlm("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT")
   cmd_err_cnt = tlm("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT")
   cmd("REACTION_WHEEL RW_NOOP_CC with CCSDS_LENGTH #{n+2}")  # Note +2 due to CCSDS already being +1
   get_REACTION_WHEEL_data()
   check("REACTION_WHEEL GENRW_HK_TLM_T COMMAND_COUNT  == #{cmd_cnt}")
   check("REACTION_WHEEL GENRW_HK_TLM_T ERROR_COUNT == #{cmd_err_cnt+1}")
end

puts "End of RW App Test Script"
