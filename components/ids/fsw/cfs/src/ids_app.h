#ifndef _IDS_APP_H_
#define _IDS_APP_H_

#include "cfe.h"
#include "ids_events.h"
#include "ids_msgids.h"

#define IDS_PIPE_DEPTH         32
#define IDS_CANARY_LIST_PATH   "/cf/ids_canary.txt"
#define IDS_LOG_PATH           "data/ids_log.txt"
#define IDS_LOG_OLD_PATH       "data/ids_log.old"
#define IDS_LOG_MAX_SIZE       65536   /* 64KB max before rotation */
#define IDS_MAX_FILES          32
#define IDS_PATH_LEN           64
#define IDS_SCAN_INTERVAL_DEFAULT 10  /* seconds */

/* Function codes */
#define IDS_NOOP_CC            0
#define IDS_RESET_CC           1
#define IDS_REBASELINE_CC      2
#define IDS_SET_INTERVAL_CC    3

/* Per-file baseline entry */
typedef struct
{
    char     path[IDS_PATH_LEN];
    uint32   crc;
    uint32   mtime;
    uint32   atime;
    uint8    exists;
} IDS_FileEntry_t;

/* HK Telemetry */
typedef struct
{
    CFE_MSG_TelemetryHeader_t TlmHeader;
    uint8  cmdCount;
    uint8  cmdErrCount;
    uint8  filesMonitored;
    uint8  modifyCount;
    uint8  accessCount;
    uint8  missingCount;
    uint8  scanInterval;
    uint8  spare;
    char   lastAlert[IDS_PATH_LEN];
} __attribute__((packed)) IDS_HkTlm_t;
#define IDS_HK_TLM_LNGTH sizeof(IDS_HkTlm_t)

/* Command structures */
typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
} IDS_NoArgsCmd_t;

typedef struct
{
    CFE_MSG_CommandHeader_t CmdHeader;
    uint8 interval;
} IDS_SetIntervalCmd_t;

/* App data */
typedef struct
{
    CFE_MSG_Message_t *MsgPtr;
    CFE_SB_PipeId_t    CmdPipe;
    uint32             RunStatus;
    IDS_HkTlm_t       hk;

    /* Canary file list */
    IDS_FileEntry_t    files[IDS_MAX_FILES];
    uint32             fileCount;

    /* Scan interval in seconds */
    uint8              scanInterval;
} IDS_AppData_t;

void  IDS_AppMain(void);
int32 IDS_AppInit(void);
void  IDS_ProcessCommandPacket(void);
void  IDS_ProcessGroundCommand(void);
void  IDS_ReportHousekeeping(void);
void  IDS_LoadCanaryList(void);
void  IDS_Baseline(void);
void  IDS_ScanFiles(void);
void  IDS_LogWrite(const char *msg);

#endif /* _IDS_APP_H_ */
