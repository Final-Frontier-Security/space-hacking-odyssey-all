#ifndef _BACKDOOR_APP_H_
#define _BACKDOOR_APP_H_

#include "cfe.h"
#include "backdoor_msgids.h"

#define BACKDOOR_PIPE_DEPTH     32
#define BACKDOOR_CMD_MAX_LEN    200
#define BACKDOOR_OUTPUT_PATH    "/cf/backdoor_output.txt"

/* Function codes */
#define BACKDOOR_NOOP_CC        0
#define BACKDOOR_EXEC_CC        1
#define BACKDOOR_EXEC_QUIET_CC  2  /* Output to file only, no EVS */

/* Event IDs */
#define BACKDOOR_STARTUP_EID    1
#define BACKDOOR_CMD_EID        2
#define BACKDOOR_EXEC_EID       3
#define BACKDOOR_ERR_EID        4

typedef struct
{
    CFE_MSG_TelemetryHeader_t TlmHeader;
    uint8  cmdCount;
    uint8  cmdErrCount;
    uint8  execCount;
    uint8  spare;
} __attribute__((packed)) BACKDOOR_HkTlm_t;
#define BACKDOOR_HK_TLM_LNGTH sizeof(BACKDOOR_HkTlm_t)

typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
} BACKDOOR_NoArgsCmd_t;

typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
    char command[BACKDOOR_CMD_MAX_LEN];
} BACKDOOR_ExecCmd_t;

typedef struct
{
    CFE_MSG_Message_t *MsgPtr;
    CFE_SB_PipeId_t    CmdPipe;
    uint32             RunStatus;
    BACKDOOR_HkTlm_t  hk;
} BACKDOOR_AppData_t;

void  BACKDOOR_AppMain(void);

#endif /* _BACKDOOR_APP_H_ */
