// ======================================================================
// \title  Generic_css.cpp
// \author jstar
// \brief  cpp file for Generic_css component implementation class
// ======================================================================

#include "css_src/Generic_css.hpp"
// #include "FpConfig.hpp"
#include "Fw/FPrimeBasicTypes.hpp"
#include <Fw/Log/LogString.hpp>


namespace Components {

  // ----------------------------------------------------------------------
  // Component construction and destruction
  // ----------------------------------------------------------------------

  Generic_css ::
    Generic_css(const char* const compName) :
      Generic_cssComponentBase(compName)
  {

    /* Initialize HWLIB */
    nos_init_link();

    int32_t status = OS_SUCCESS;
    uint16_t Voltage[GENERIC_CSS_NUM_CHANNELS];

    HkTelemetryPkt.CommandCount = 0;
    HkTelemetryPkt.CommandErrorCount = 0;
    HkTelemetryPkt.DeviceCount = 0;
    HkTelemetryPkt.DeviceErrorCount = 0;
    HkTelemetryPkt.DeviceEnabled = GENERIC_CSS_DEVICE_ENABLED;

    /* Open device specific protocols */
    Generic_CSSI2c.handle = GENERIC_CSS_CFG_HANDLE;
    Generic_CSSI2c.isOpen = PORT_CLOSED;
    Generic_CSSI2c.speed = GENERIC_CSS_CFG_BAUDRATE_HZ;
    Generic_CSSI2c.addr = GENERIC_CSS_I2C_ADDRESS;
    status = i2c_master_init(&Generic_CSSI2c);
    if (status == OS_SUCCESS)
    {
        printf("I2C device %d configured with speed %d \n", Generic_CSSI2c.handle, Generic_CSSI2c.speed);
    }
    else
    {
        printf("I2C device %d failed to initialize! \n", Generic_CSSI2c.handle);
    }

    // status = i2c_master_close(&Generic_CSSI2c);
  }

  Generic_css ::
    ~Generic_css()
  {
    // Close the device 
    i2c_master_close(&Generic_CSSI2c);

    nos_destroy_link();
  }

  // ----------------------------------------------------------------------
  // Handler implementations for commands
  // ----------------------------------------------------------------------


  void Generic_css :: NOOP_cmdHandler(FwOpcodeType opCode, U32 cmdSeq){
    HkTelemetryPkt.CommandCount++;

    Fw::LogStringArg log_msg("NOOP command success!");
    this->log_ACTIVITY_HI_TELEM(log_msg);

    this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
    this->tlmWrite_DeviceEnabled(get_active_state(HkTelemetryPkt.DeviceEnabled));
    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Generic_css :: ENABLE_cmdHandler(FwOpcodeType opCode, U32 cmdSeq){
    int32_t status = OS_SUCCESS;

    if(HkTelemetryPkt.DeviceEnabled == GENERIC_CSS_DEVICE_DISABLED)
    {
      HkTelemetryPkt.CommandCount++;

      Generic_CSSI2c.handle = GENERIC_CSS_CFG_HANDLE;
      Generic_CSSI2c.isOpen = PORT_CLOSED;
      Generic_CSSI2c.speed  = GENERIC_CSS_CFG_BAUDRATE_HZ;
      Generic_CSSI2c.addr   = GENERIC_CSS_I2C_ADDRESS;

      status = i2c_master_init(&Generic_CSSI2c);
      if(status == OS_SUCCESS)
      {
        HkTelemetryPkt.DeviceEnabled = GENERIC_CSS_DEVICE_ENABLED;
        HkTelemetryPkt.DeviceCount++;

        Fw::LogStringArg log_msg("Enable command success!");
        this->log_ACTIVITY_HI_TELEM(log_msg);
      }
      else
      {
        HkTelemetryPkt.DeviceErrorCount++;

        Fw::LogStringArg log_msg("Enable command failed to init I2C!");
        this->log_ACTIVITY_HI_TELEM(log_msg);
      }
    }
    else
    {
      HkTelemetryPkt.CommandErrorCount++;

      Fw::LogStringArg log_msg("Enable failed, already Enabled!");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }

    this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
    this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
    this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
    this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);
    this->tlmWrite_DeviceEnabled(get_active_state(HkTelemetryPkt.DeviceEnabled));

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Generic_css :: DISABLE_cmdHandler(FwOpcodeType opCode, U32 cmdSeq){
    int32_t status = OS_SUCCESS;

    if(HkTelemetryPkt.DeviceEnabled == GENERIC_CSS_DEVICE_ENABLED)
    {
      HkTelemetryPkt.CommandCount++;

      status = i2c_master_close(&Generic_CSSI2c);
      if(status == OS_SUCCESS)
      {
        HkTelemetryPkt.DeviceEnabled = GENERIC_CSS_DEVICE_DISABLED;
        HkTelemetryPkt.DeviceCount++;

        Fw::LogStringArg log_msg("Disable command success!");
        this->log_ACTIVITY_HI_TELEM(log_msg);
      }
      else
      {
        HkTelemetryPkt.DeviceErrorCount++;
        
        Fw::LogStringArg log_msg("Disable command failed to close I2C!");
        this->log_ACTIVITY_HI_TELEM(log_msg);
      }
    }
    else
    {
      HkTelemetryPkt.CommandErrorCount++;

      Fw::LogStringArg log_msg("Disable failed, already Disabled!");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }

    this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
    this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
    this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
    this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);
    this->tlmWrite_DeviceEnabled(get_active_state(HkTelemetryPkt.DeviceEnabled));

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Generic_css :: REQUEST_HOUSEKEEPING_cmdHandler(FwOpcodeType opCode, U32 cmdSeq){

    if(HkTelemetryPkt.DeviceEnabled == GENERIC_CSS_DEVICE_ENABLED)
    {
      HkTelemetryPkt.CommandCount++;
      this->tlmWrite_ADCVoltage0(Generic_CSSData.Voltage[0]);
      this->tlmWrite_ADCVoltage1(Generic_CSSData.Voltage[1]);
      this->tlmWrite_ADCVoltage2(Generic_CSSData.Voltage[2]);
      this->tlmWrite_ADCVoltage3(Generic_CSSData.Voltage[3]);
      this->tlmWrite_ADCVoltage4(Generic_CSSData.Voltage[4]);
      this->tlmWrite_ADCVoltage5(Generic_CSSData.Voltage[5]);

      this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
      this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
      this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
      this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);
      this->tlmWrite_DeviceEnabled(get_active_state(HkTelemetryPkt.DeviceEnabled));

      Fw::LogStringArg log_msg("Requested Housekeeping!");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }
    else
    {
      Fw::LogStringArg log_msg("HK failed, Device Disabled!");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }


    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

  void Generic_css :: RESET_COUNTERS_cmdHandler(FwOpcodeType opCode, U32 cmdSeq){
    HkTelemetryPkt.CommandCount = 0;
    HkTelemetryPkt.CommandErrorCount = 0;
    HkTelemetryPkt.DeviceCount = 0;
    HkTelemetryPkt.DeviceErrorCount = 0;

    Fw::LogStringArg log_msg("Reset Counters command successful!");
    this->log_ACTIVITY_HI_TELEM(log_msg);
    this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
    this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
    this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
    this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);

    this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
  }

 // GENERIC_CSS_RequestData
 void Generic_css :: REQUEST_DATA_cmdHandler(FwOpcodeType opCode, U32 cmdSeq) {

  int32_t status = OS_SUCCESS;

  if(HkTelemetryPkt.DeviceEnabled == GENERIC_CSS_DEVICE_ENABLED){
    HkTelemetryPkt.CommandCount++;

    status = GENERIC_CSS_RequestData(&Generic_CSSI2c, &Generic_CSSData);
    if (status == OS_SUCCESS)
    {
      HkTelemetryPkt.DeviceCount++;
      
      Fw::LogStringArg log_msg("Request Data command success\n");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }
    else
    {
      HkTelemetryPkt.DeviceErrorCount++;
      Fw::LogStringArg log_msg("Request Data command failed!\n");
      this->log_ACTIVITY_HI_TELEM(log_msg);
    }

  }
  else
  {
    HkTelemetryPkt.CommandErrorCount++;
    Fw::LogStringArg log_msg("Request Data failed, Device Disabled!");
    this->log_ACTIVITY_HI_TELEM(log_msg);

  }

  this->tlmWrite_ADCVoltage0(Generic_CSSData.Voltage[0]);
  this->tlmWrite_ADCVoltage1(Generic_CSSData.Voltage[1]);
  this->tlmWrite_ADCVoltage2(Generic_CSSData.Voltage[2]);
  this->tlmWrite_ADCVoltage3(Generic_CSSData.Voltage[3]);
  this->tlmWrite_ADCVoltage4(Generic_CSSData.Voltage[4]);
  this->tlmWrite_ADCVoltage5(Generic_CSSData.Voltage[5]);
  this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
  this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
  this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
  this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);

  // Tell the fprime command system that we have completed the processing of the supplied command with OK status
  this->cmdResponse_out(opCode, cmdSeq, Fw::CmdResponse::OK);
}

void Generic_css :: updateData_handler(const FwIndexType portNum, U32 context)
{
  int32_t status = OS_SUCCESS;

  status = GENERIC_CSS_RequestData(&Generic_CSSI2c, &Generic_CSSData);

  if(status == OS_SUCCESS)
  {
    HkTelemetryPkt.DeviceCount++;
    this->CSSout_out(0, Generic_CSSData.Voltage[0], Generic_CSSData.Voltage[1], Generic_CSSData.Voltage[2], Generic_CSSData.Voltage[3], Generic_CSSData.Voltage[4], Generic_CSSData.Voltage[5]);
  }
  else
  {
    HkTelemetryPkt.DeviceErrorCount++;
  }
}

void Generic_css :: updateTlm_handler(const FwIndexType portNum, U32 context)
{
  this->tlmWrite_ADCVoltage0(Generic_CSSData.Voltage[0]);
  this->tlmWrite_ADCVoltage1(Generic_CSSData.Voltage[1]);
  this->tlmWrite_ADCVoltage2(Generic_CSSData.Voltage[2]);
  this->tlmWrite_ADCVoltage3(Generic_CSSData.Voltage[3]);
  this->tlmWrite_ADCVoltage4(Generic_CSSData.Voltage[4]);
  this->tlmWrite_ADCVoltage5(Generic_CSSData.Voltage[5]);
  this->tlmWrite_CommandCount(HkTelemetryPkt.CommandCount);
  this->tlmWrite_CommandErrorCount(HkTelemetryPkt.CommandErrorCount);
  this->tlmWrite_DeviceCount(HkTelemetryPkt.DeviceCount);
  this->tlmWrite_DeviceErrorCount(HkTelemetryPkt.DeviceErrorCount);
}

inline Generic_css_ActiveState Generic_css :: get_active_state(uint8_t DeviceEnabled)
{
  Generic_css_ActiveState state;

  if(DeviceEnabled == GENERIC_CSS_DEVICE_ENABLED)
  {
    state.e = Generic_css_ActiveState::ENABLED;
  }
  else
  {
    state.e = Generic_css_ActiveState::DISABLED;
  }

  return state;
}


}

 