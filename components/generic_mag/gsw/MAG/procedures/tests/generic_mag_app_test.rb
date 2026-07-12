require 'cosmos'
require 'cosmos/script'
require "generic_mag_lib.rb"

##
## This script tests the standard cFS component application functionality.
## Currently this includes: 
##   Housekeeping, request telemetry to be published on the software bus
##   NOOP, no operation but confirm correct counters increment
##   Reset counters, increment as done in NOOP and confirm ability to clear repeatably
##   Invalid ground command, confirm bad lengths and codes are rejected
##


##
##   Housekeeping, request telemetry to be published on the software bus
##
MAG_TEST_LOOP_COUNT.times do |n|
    get_generic_mag_hk()
end


##
## NOOP, no operation but confirm correct counters increment
##
MAG_TEST_LOOP_COUNT.times do |n|
    generic_mag_cmd("MAG MAG_NOOP_CC")
end


##
## Reset counters, increment as done in NOOP and confirm ability to clear repeatably
##
MAG_TEST_LOOP_COUNT.times do |n|
    generic_mag_cmd("MAG MAG_NOOP_CC")
    cmd("MAG MAG_RST_COUNTERS_CC") # Note standard `cmd` as we can't reset counters and then confirm increment
    get_generic_mag_hk()
    check("MAG MAG_HK_TLM CMD_COUNT == 0")
    check("MAG MAG_HK_TLM CMD_ERR_COUNT == 0")
end


##
##   Invalid ground command, confirm bad lengths and codes are rejected
##
MAG_TEST_LOOP_COUNT.times do |n|
    # Bad length
    cmd_cnt = tlm("MAG MAG_HK_TLM CMD_COUNT")
    cmd_err_cnt = tlm("MAG MAG_HK_TLM CMD_ERR_COUNT")
    cmd("MAG MAG_NOOP_CC with CCSDS_LENGTH #{n+2}") # Note +2 due to CCSDS already being +1
    get_generic_mag_hk()
    check("MAG MAG_HK_TLM CMD_COUNT == #{cmd_cnt}")
    check("MAG MAG_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")
end

for n in 6..(5 + MAG_TEST_LOOP_COUNT)
    # Bad command codes
    cmd_cnt = tlm("MAG MAG_HK_TLM CMD_COUNT")
    cmd_err_cnt = tlm("MAG MAG_HK_TLM CMD_ERR_COUNT")
    cmd("MAG MAG_NOOP_CC with CCSDS_FC #{n+1}")
    get_generic_mag_hk()
    check("MAG MAG_HK_TLM CMD_COUNT == #{cmd_cnt}")
    check("MAG MAG_HK_TLM CMD_ERR_COUNT == #{cmd_err_cnt+1}")
end
