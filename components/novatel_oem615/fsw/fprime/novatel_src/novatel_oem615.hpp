// ======================================================================
// \title  novatel_oem615.hpp
// \author jstar
// \brief  hpp file for novatel_oem615 component implementation class
// ======================================================================

#ifndef Components_novatel_oem615_HPP
#define Components_novatel_oem615_HPP

#include "novatel_src/novatel_oem615ComponentAc.hpp"

extern "C"{
  #include "novatel_oem615_device.h"
  #include "libuart.h"
}
#include "nos_link.h"

namespace Components {

  class novatel_oem615 :
    public novatel_oem615ComponentBase
  {

    public:

    uart_info_t Novatel_oem615Uart;                         /* Hardware protocol definition */
    NOVATEL_OEM615_Device_Data_tlm_t Novatel_oem615Data; 

      // ----------------------------------------------------------------------
      // Component construction and destruction
      // ----------------------------------------------------------------------

      //! Construct novatel_oem615 object
      novatel_oem615(
          const char* const compName //!< The component name
      );

      //! Destroy novatel_oem615 object
      ~novatel_oem615();

    private:


      // ----------------------------------------------------------------------
      // Handler implementations for commands
      // ----------------------------------------------------------------------

      void REQUEST_DATA_cmdHandler(
        FwOpcodeType opCode, 
        U32 cmdSeq
      ) override;

      void SERIAL_CONFIG_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        const I8 log_type
      ) override;

      void LOG_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        const I8 log_type2,
        const I8 period
      ) override;

      void UNLOG_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq,
        const I8 log_type3
      ) override;

      void UNLOG_ALL_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;
      

  };

}

#endif
