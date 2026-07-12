require 'cosmos'
require 'cosmos/script'
require "generic_radio_lib.rb"


safe_RADIO()

##
##   Housekeeping, request telemetry to be published on the software bus
##
RADIO_TEST_LOOP_COUNT.times do |n|
  get_RADIO_hk()
end

##
## NOOP, no operation but confirm correct counters increment
##
RADIO_TEST_LOOP_COUNT.times do |n|
  RADIO_cmd("RADIO RADIO_NOOP_CC")
end

##
## Reset counters, increment as done in NOOP and confirm ability to clear repeatably
##
RADIO_TEST_LOOP_COUNT.times do |n|
  RADIO_cmd("RADIO RADIO_NOOP_CC")
  cmd("RADIO RADIO_RST_COUNTERS_CC")
  get_RADIO_hk()
  check("RADIO RADIO_HK_TLM CMD_COUNT == 0")
  check("RADIO RADIO_HK_TLM CMD_ERR_COUNT == 0")
end

##
## injecting bad commmands, checking error counters increase
##
RADIO_TEST_LOOP_COUNT.times do |n|
   # Bad length
   cmd_cnt = tlm("RADIO RADIO_HK_TLM CMD_COUNT")
   cmd_err_cnt = tlm("RADIO RADIO_HK_TLM CMD_ERR_COUNT")
   cmd("RADIO RADIO_NOOP_CC with CCSDS_LENGTH #{n+2}") # Note +2 due to CCSDS already being +1
   get_RADIO_hk()
   check("RADIO RADIO_HK_TLM CMD_COUNT == #{cmd_cnt}")
   check("RADIO RADIO_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")
end

for n in 6..(5 + RADIO_TEST_LOOP_COUNT)
  # Bad command codes
  cmd_cnt = tlm("RADIO RADIO_HK_TLM CMD_COUNT")
  cmd_err_cnt = tlm("RADIO RADIO_HK_TLM CMD_ERR_COUNT")
  cmd("RADIO RADIO_NOOP_CC with CCSDS_FC #{n+1}")
  get_RADIO_hk()
  check("RADIO RADIO_HK_TLM CMD_COUNT == #{cmd_cnt}")
  check("RADIO RADIO_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")
end