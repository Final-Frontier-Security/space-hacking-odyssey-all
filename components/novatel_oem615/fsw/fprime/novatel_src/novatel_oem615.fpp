module Components {
    @ GPS
    active component novatel_oem615 {

        @ Request Data Cmd
        async command REQUEST_DATA(
        )

        @ Greeting event with maximum greeting length of 40 characters
        event TELEM(
            log_info: string size 40 @< 
        ) severity activity high format "novatel_oem615: {}"


        @ Serial Config Cmd
        async command SERIAL_CONFIG(
            log_type: I8 @< Log Type
        )

        @ Log Cmd
        async command LOG(
            log_type2: I8 @< Log Type
            period: I8 @< Period between logs
        )

        @ Unlog Cmd
        async command UNLOG(
            log_type3: I8 @< Greeting to repeat in the Hello event
        )

        @ UNLOG_ALL Cmd
        async command UNLOG_ALL(
        )

        @ Weeks
        telemetry Weeks: U16

        @ SecondsIntoWeek
        telemetry SecondsIntoWeek: U32

        @ Fractions
        telemetry Fractions: F64

        @ ECEFX
        telemetry ECEFX: F64

        @ ECEFY
        telemetry ECEFY: F64

        @ ECEFZ
        telemetry ECEFZ: F64

        @ VelX
        telemetry VelX: F64

        @ VelY
        telemetry VelY: F64

        @ VelZ
        telemetry VelZ: F64

        @ lat
        telemetry lat: F32
        
        @ lon
        telemetry lon: F32

        @ alt
        telemetry alt: F32

        ##############################################################################
        #### Uncomment the following examples to start customizing your component ####
        ##############################################################################

        # @ Example async command
        # async command COMMAND_NAME(param_name: U32)

        # @ Example telemetry counter
        # telemetry ExampleCounter: U64

        # @ Example event
        # event ExampleStateEvent(example_state: Fw.On) severity activity high id 0 format "State set to {}"

        # @ Example port: receiving calls from the rate group
        # sync input port run: Svc.Sched

        # @ Example parameter
        # param PARAMETER_NAME: U32

        ###############################################################################
        # Standard AC Ports: Required for Channels, Events, Commands, and Parameters  #
        ###############################################################################
        @ Port for requesting the current time
        time get port timeCaller

        @ Port for sending command registrations
        command reg port cmdRegOut

        @ Port for receiving commands
        command recv port cmdIn

        @ Port for sending command responses
        command resp port cmdResponseOut

        @ Port for sending textual representation of events
        text event port logTextOut

        @ Port for sending events to downlink
        event port logOut

        @ Port for sending telemetry channels to downlink
        telemetry port tlmOut

        @ Port to return the value of a parameter
        param get port prmGetOut

        @Port to set the value of a parameter
        param set port prmSetOut

    }
}