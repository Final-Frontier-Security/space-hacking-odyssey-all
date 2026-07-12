/*
** IPS - Intrusion Prevention System for cFS
**
** Monitors the ES app table for unauthorized applications.
** Compares running apps against an allowlist in /cf/ips_allowlist.txt.
** Unauthorized apps are reported via EVS and optionally unloaded.
*/

#include "ips_app.h"
#include "ips_perfids.h"
#include <string.h>
#include <stdio.h>

IPS_AppData_t IPS_AppData;

void IPS_AppMain(void)
{
    int32 status = OS_SUCCESS;

    CFE_ES_PerfLogEntry(IPS_PERF_ID);

    status = IPS_AppInit();
    if (status != CFE_SUCCESS)
    {
        IPS_AppData.RunStatus = CFE_ES_RunStatus_APP_ERROR;
    }

    while (CFE_ES_RunLoop(&IPS_AppData.RunStatus) == true)
    {
        CFE_ES_PerfLogExit(IPS_PERF_ID);

        status = CFE_SB_ReceiveBuffer((CFE_SB_Buffer_t **)&IPS_AppData.MsgPtr,
                                       IPS_AppData.CmdPipe, 5000);

        CFE_ES_PerfLogEntry(IPS_PERF_ID);

        if (status == CFE_SUCCESS)
        {
            IPS_ProcessCommandPacket();
        }
        else if (status == CFE_SB_TIME_OUT)
        {
            /* Timeout - use as wakeup to scan */
            IPS_ScanApps();
            IPS_ReportHousekeeping();
        }
        else
        {
            CFE_EVS_SendEvent(IPS_PIPE_ERR_EID, CFE_EVS_EventType_ERROR,
                "IPS: SB Pipe Read Error = %d", (int)status);
            IPS_AppData.RunStatus = CFE_ES_RunStatus_APP_ERROR;
        }
    }

    CFE_ES_PerfLogExit(IPS_PERF_ID);
    CFE_ES_ExitApp(IPS_AppData.RunStatus);
}

int32 IPS_AppInit(void)
{
    int32 status;

    IPS_AppData.RunStatus = CFE_ES_RunStatus_APP_RUN;
    IPS_AppData.mode = IPS_MODE_MONITOR;

    status = CFE_EVS_Register(NULL, 0, CFE_EVS_EventFilter_BINARY);
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_CreatePipe(&IPS_AppData.CmdPipe, IPS_PIPE_DEPTH, "IPS_CMD_PIPE");
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_Subscribe(CFE_SB_ValueToMsgId(IPS_CMD_MID), IPS_AppData.CmdPipe);
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_Subscribe(CFE_SB_ValueToMsgId(IPS_REQ_HK_MID), IPS_AppData.CmdPipe);
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_Subscribe(CFE_SB_ValueToMsgId(IPS_WAKEUP_MID), IPS_AppData.CmdPipe);
    if (status != CFE_SUCCESS) return status;

    CFE_MSG_Init(CFE_MSG_PTR(IPS_AppData.hk.TlmHeader),
                 CFE_SB_ValueToMsgId(IPS_HK_TLM_MID),
                 IPS_HK_TLM_LNGTH);

    /* Initialize counters */
    IPS_AppData.hk.cmdCount = 0;
    IPS_AppData.hk.cmdErrCount = 0;
    IPS_AppData.hk.violationCount = 0;
    IPS_AppData.hk.appsScanned = 0;
    IPS_AppData.hk.mode = IPS_AppData.mode;
    memset(IPS_AppData.hk.lastViolation, 0, sizeof(IPS_AppData.hk.lastViolation));

    /* Load the allowlist */
    IPS_LoadAllowlist();

    /* Record our own app ID as the high water mark — any app loaded after us is suspicious */
    {
        CFE_ES_AppId_t myId;
        if (CFE_ES_GetAppID(&myId) == CFE_SUCCESS)
        {
            IPS_AppData.highWaterMark = CFE_ResourceId_ToInteger(CFE_RESOURCEID_UNWRAP(myId));
        }
        else
        {
            IPS_AppData.highWaterMark = 0;
        }
    }

    CFE_EVS_SendEvent(IPS_STARTUP_INF_EID, CFE_EVS_EventType_INFORMATION,
        "IPS: App initialized. Mode=%s, Allowlist=%d apps, BaseID=%lu",
        IPS_AppData.mode == IPS_MODE_ENFORCE ? "ENFORCE" : "MONITOR",
        (int)IPS_AppData.allowlistCount,
        (unsigned long)IPS_AppData.highWaterMark);

    return CFE_SUCCESS;
}

void IPS_LoadAllowlist(void)
{
    osal_id_t fd;
    int32 status;
    char line[IPS_APP_NAME_LEN];
    int32 bytes_read;
    int idx = 0;
    int line_pos = 0;

    IPS_AppData.allowlistCount = 0;
    memset(IPS_AppData.allowlist, 0, sizeof(IPS_AppData.allowlist));

    status = OS_OpenCreate(&fd, IPS_ALLOWLIST_PATH, OS_FILE_FLAG_NONE, OS_READ_ONLY);
    if (status != OS_SUCCESS)
    {
        CFE_EVS_SendEvent(IPS_ALLOWLIST_ERR_EID, CFE_EVS_EventType_ERROR,
            "IPS: Failed to open allowlist at %s (err=%d)", IPS_ALLOWLIST_PATH, (int)status);
        return;
    }

    /* Read file character by character to parse lines */
    char ch;
    while (idx < IPS_MAX_APPS)
    {
        bytes_read = OS_read(fd, &ch, 1);
        if (bytes_read <= 0) break;

        if (ch == '\n' || ch == '\r')
        {
            if (line_pos > 0)
            {
                line[line_pos] = '\0';
                /* Skip comments and empty lines */
                if (line[0] != '#' && line_pos > 0)
                {
                    strncpy(IPS_AppData.allowlist[idx], line, IPS_APP_NAME_LEN - 1);
                    IPS_AppData.allowlist[idx][IPS_APP_NAME_LEN - 1] = '\0';
                    idx++;
                }
                line_pos = 0;
            }
        }
        else
        {
            if (line_pos < IPS_APP_NAME_LEN - 1)
            {
                line[line_pos++] = ch;
            }
        }
    }
    /* Handle last line without newline */
    if (line_pos > 0 && idx < IPS_MAX_APPS)
    {
        line[line_pos] = '\0';
        if (line[0] != '#')
        {
            strncpy(IPS_AppData.allowlist[idx], line, IPS_APP_NAME_LEN - 1);
            idx++;
        }
    }

    OS_close(fd);
    IPS_AppData.allowlistCount = idx;

    CFE_EVS_SendEvent(IPS_ALLOWLIST_LOAD_EID, CFE_EVS_EventType_INFORMATION,
        "IPS: Loaded %d apps from allowlist", idx);
}

static int IPS_IsAllowed(const char *app_name)
{
    uint32 i;
    for (i = 0; i < IPS_AppData.allowlistCount; i++)
    {
        if (strncmp(IPS_AppData.allowlist[i], app_name, IPS_APP_NAME_LEN) == 0)
        {
            return 1;
        }
    }
    return 0;
}

void IPS_ScanApps(void)
{
    CFE_ES_AppInfo_t appInfo;
    uint32 scanned = 0;
    uint32 i;
    CFE_Status_t status;

    /* Scan from our ID downward to find all boot-loaded apps */
    for (i = 0; i <= IPS_AppData.highWaterMark; i++)
    {
        CFE_ES_AppId_t appId;
        uint32 candidateId = IPS_AppData.highWaterMark - i;
        CFE_ResourceId_t resId = CFE_ResourceId_FromInteger(candidateId);
        appId = CFE_ES_APPID_C(resId);

        status = CFE_ES_GetAppInfo(&appInfo, appId);
        if (status != CFE_SUCCESS)
        {
            break; /* No more valid apps below this point */
        }

        scanned++;

        if (!IPS_IsAllowed(appInfo.Name))
        {
            IPS_AppData.hk.violationCount++;
            strncpy(IPS_AppData.hk.lastViolation, appInfo.Name,
                    sizeof(IPS_AppData.hk.lastViolation) - 1);

            CFE_EVS_SendEvent(IPS_VIOLATION_EID, CFE_EVS_EventType_CRITICAL,
                "IPS: UNAUTHORIZED APP '%s' detected! [violation #%d]",
                appInfo.Name, IPS_AppData.hk.violationCount);

            if (IPS_AppData.mode == IPS_MODE_ENFORCE)
            {
                int32 del_status = CFE_ES_DeleteApp(appId);
                if (del_status == CFE_SUCCESS)
                {
                    CFE_EVS_SendEvent(IPS_APP_REMOVED_EID, CFE_EVS_EventType_CRITICAL,
                        "IPS: App '%s' REMOVED from system", appInfo.Name);
                }
                else
                {
                    CFE_EVS_SendEvent(IPS_APP_REMOVED_EID, CFE_EVS_EventType_ERROR,
                        "IPS: Failed to remove '%s' (err=%d)", appInfo.Name, (int)del_status);
                }
            }
        }
    }

    /* Also scan above our ID for post-boot apps */
    for (i = 1; i <= 32; i++)
    {
        CFE_ES_AppId_t appId;
        uint32 candidateId = IPS_AppData.highWaterMark + i;
        CFE_ResourceId_t resId = CFE_ResourceId_FromInteger(candidateId);
        appId = CFE_ES_APPID_C(resId);

        status = CFE_ES_GetAppInfo(&appInfo, appId);
        if (status != CFE_SUCCESS)
        {
            continue;
        }

        scanned++;

        if (!IPS_IsAllowed(appInfo.Name))
        {
            IPS_AppData.hk.violationCount++;
            strncpy(IPS_AppData.hk.lastViolation, appInfo.Name,
                    sizeof(IPS_AppData.hk.lastViolation) - 1);

            CFE_EVS_SendEvent(IPS_VIOLATION_EID, CFE_EVS_EventType_CRITICAL,
                "IPS: UNAUTHORIZED APP '%s' detected! [violation #%d]",
                appInfo.Name, IPS_AppData.hk.violationCount);

            if (IPS_AppData.mode == IPS_MODE_ENFORCE)
            {
                int32 del_status = CFE_ES_DeleteApp(appId);
                if (del_status == CFE_SUCCESS)
                {
                    CFE_EVS_SendEvent(IPS_APP_REMOVED_EID, CFE_EVS_EventType_CRITICAL,
                        "IPS: App '%s' REMOVED from system", appInfo.Name);
                }
                else
                {
                    CFE_EVS_SendEvent(IPS_APP_REMOVED_EID, CFE_EVS_EventType_ERROR,
                        "IPS: Failed to remove '%s' (err=%d)", appInfo.Name, (int)del_status);
                }
            }
        }
    }

    IPS_AppData.hk.appsScanned = scanned;
}

void IPS_ProcessCommandPacket(void)
{
    CFE_SB_MsgId_t msgId = CFE_SB_INVALID_MSG_ID;
    CFE_MSG_GetMsgId(IPS_AppData.MsgPtr, &msgId);

    switch (CFE_SB_MsgIdToValue(msgId))
    {
        case IPS_CMD_MID:
            IPS_ProcessGroundCommand();
            break;
        case IPS_REQ_HK_MID:
            IPS_ReportHousekeeping();
            break;
        case IPS_WAKEUP_MID:
            IPS_ScanApps();
            break;
        default:
            IPS_AppData.hk.cmdErrCount++;
            break;
    }
}

void IPS_ProcessGroundCommand(void)
{
    CFE_MSG_FcnCode_t cmdCode = 0;
    CFE_MSG_GetFcnCode(IPS_AppData.MsgPtr, &cmdCode);

    switch (cmdCode)
    {
        case IPS_NOOP_CC:
            IPS_AppData.hk.cmdCount++;
            CFE_EVS_SendEvent(IPS_CMD_NOOP_EID, CFE_EVS_EventType_INFORMATION,
                "IPS: NOOP received. Mode=%s, Violations=%d",
                IPS_AppData.mode == IPS_MODE_ENFORCE ? "ENFORCE" : "MONITOR",
                IPS_AppData.hk.violationCount);
            break;

        case IPS_RESET_CC:
            IPS_AppData.hk.cmdCount = 0;
            IPS_AppData.hk.cmdErrCount = 0;
            IPS_AppData.hk.violationCount = 0;
            memset(IPS_AppData.hk.lastViolation, 0, sizeof(IPS_AppData.hk.lastViolation));
            CFE_EVS_SendEvent(IPS_CMD_RESET_EID, CFE_EVS_EventType_INFORMATION,
                "IPS: Counters reset");
            break;

        case IPS_SET_MODE_CC:
        {
            IPS_SetModeCmd_t *cmd = (IPS_SetModeCmd_t *)IPS_AppData.MsgPtr;
            if (cmd->mode <= IPS_MODE_ENFORCE)
            {
                IPS_AppData.mode = cmd->mode;
                IPS_AppData.hk.mode = cmd->mode;
                IPS_AppData.hk.cmdCount++;
                CFE_EVS_SendEvent(IPS_CMD_NOOP_EID, CFE_EVS_EventType_INFORMATION,
                    "IPS: Mode set to %s",
                    cmd->mode == IPS_MODE_ENFORCE ? "ENFORCE" : "MONITOR");
            }
            else
            {
                IPS_AppData.hk.cmdErrCount++;
            }
            break;
        }

        default:
            IPS_AppData.hk.cmdErrCount++;
            CFE_EVS_SendEvent(IPS_CMD_ERR_EID, CFE_EVS_EventType_ERROR,
                "IPS: Invalid command code %d", cmdCode);
            break;
    }
}

void IPS_ReportHousekeeping(void)
{
    IPS_AppData.hk.mode = IPS_AppData.mode;
    CFE_SB_TimeStampMsg((CFE_MSG_Message_t *)&IPS_AppData.hk);
    CFE_SB_TransmitMsg((CFE_MSG_Message_t *)&IPS_AppData.hk, true);
}
