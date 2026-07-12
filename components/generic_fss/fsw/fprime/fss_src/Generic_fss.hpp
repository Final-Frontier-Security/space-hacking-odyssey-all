// ======================================================================
// \title  Generic_fss.hpp
// \author jstar
// \brief  hpp file for Generic_fss component implementation class
// ======================================================================

#ifndef Components_Generic_fss_HPP
#define Components_Generic_fss_HPP

#include "fss_src/Generic_fssComponentAc.hpp"
#include "fss_src/Generic_fss_ActiveStateEnumAc.hpp"

extern "C"{
  #include "generic_fss_device.h"
  #include "generic_fss_platform_cfg.h"
  #include "libuart.h"
  }

#include "nos_link.h"

typedef struct
{
    uint8_t                         DeviceCount;
    uint8_t                         DeviceErrorCount;
    uint8_t                         CommandErrorCount;
    uint8_t                         CommandCount;
    uint8_t                         DeviceEnabled;
} FSS_Hk_tlm_t;
#define FSS_HK_TLM_LNGTH sizeof(FSS_Hk_tlm_t)

#define GENERIC_FSS_DEVICE_DISABLED 0
#define GENERIC_FSS_DEVICE_ENABLED  1

namespace Components {

  class Generic_fss :
    public Generic_fssComponentBase
  {

    public:

    spi_info_t FssSpi;
    GENERIC_FSS_Device_Data_tlm_t FSSData;
    FSS_Hk_tlm_t HkTelemetryPkt;

      // ----------------------------------------------------------------------
      // Component construction and destruction
      // ----------------------------------------------------------------------

      //! Construct Generic_fss object
      Generic_fss(
          const char* const compName //!< The component name
      );

      //! Destroy Generic_fss object
      ~Generic_fss();

    private:

      // ----------------------------------------------------------------------
      // Handler implementations for commands
      // ----------------------------------------------------------------------

      void NOOP_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;

      void RESET_COUNTERS_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;

      void ENABLE_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;

      void DISABLE_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;

      void REQUEST_HOUSEKEEPING_cmdHandler(
        FwOpcodeType opCode,
        U32 cmdSeq
      ) override;

      void REQUEST_DATA_cmdHandler(
          FwOpcodeType opCode, //!< The opcode
          U32 cmdSeq //!< The command sequence number
      ) override;

      void updateData_handler(
        const FwIndexType portNum, //!< The port number
        U32 context //!< The call order
      ) override;

      void updateTlm_handler(
        const FwIndexType portNum, //!< The port number
        U32 context //!< The call order
      ) override;

      inline Generic_fss_ActiveState get_active_state(uint8_t DeviceEnabled);

  };

}

#endif
