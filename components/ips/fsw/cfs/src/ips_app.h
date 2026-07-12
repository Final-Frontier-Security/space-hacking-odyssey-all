#ifndef _IPS_APP_H_
#define _IPS_APP_H_

#include "cfe.h"
#include "ips_events.h"
#include "ips_msgids.h"

#define IPS_PIPE_DEPTH         32
#define IPS_ALLOWLIST_PATH     "/cf/ips_allowlist.txt"
#define IPS_MAX_APPS           64
#define IPS_APP_NAME_LEN       OS_MAX_API_NAME

/* Function codes */
#define IPS_NOOP_CC            0
#define IPS_RESET_CC           1
#define IPS_SET_MODE_CC        2

/* Modes */
#define IPS_MODE_MONITOR       0
#define IPS_MODE_ENFORCE       1

typedef struct
{
    CFE_MSG_TelemetryHeader_t TlmHeader;
    uint8  cmdCount;
    uint8  cmdErrCount;
    uint8  mode;
    uint8  violationCount;
    uint8  appsScanned;
    char   lastViolation[IPS_APP_NAME_LEN];
} __attribute__((packed)) IPS_HkTlm_t;
#define IPS_HK_TLM_LNGTH sizeof(IPS_HkTlm_t)

typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
} IPS_NoArgsCmd_t;

typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
    uint8 mode;
} IPS_SetModeCmd_t;

typedef struct
{
    CFE_MSG_Message_t *MsgPtr;
    CFE_SB_PipeId_t    CmdPipe;
    uint32             RunStatus;
    IPS_HkTlm_t       hk;

    /* Allowlist */
    char               allowlist[IPS_MAX_APPS][IPS_APP_NAME_LEN];
    uint32             allowlistCount;
    uint8              mode;

    /* Scan baseline: our own app ID marks the end of legitimate apps */
    uint32             highWaterMark;
} IPS_AppData_t;

void  IPS_AppMain(void);
int32 IPS_AppInit(void);
void  IPS_ProcessCommandPacket(void);
void  IPS_ProcessGroundCommand(void);
void  IPS_ReportHousekeeping(void);
void  IPS_LoadAllowlist(void);
void  IPS_ScanApps(void);

#endif /* _IPS_APP_H_ */
