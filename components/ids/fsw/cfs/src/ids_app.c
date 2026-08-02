/*
** IDS - Intrusion Detection System for cFS
**
** Monitors canary files in /data/ for access and modification.
** Detects: file read (atime change), file modification (mtime/CRC change),
** and file deletion.
** Reports via EVS events, HK telemetry, and a local log file.
*/

#include "ids_app.h"
#include "ids_perfids.h"
#include <string.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

IDS_AppData_t IDS_AppData;

/* Forward declarations */
static uint32 IDS_ComputeFileCRC(const char *path);
static void IDS_LogRotate(void);

void IDS_AppMain(void)
{
    int32 status = OS_SUCCESS;

    CFE_ES_PerfLogEntry(IDS_PERF_ID);

    status = IDS_AppInit();
    if (status != CFE_SUCCESS)
    {
        IDS_AppData.RunStatus = CFE_ES_RunStatus_APP_ERROR;
    }

    while (CFE_ES_RunLoop(&IDS_AppData.RunStatus) == true)
    {
        CFE_ES_PerfLogExit(IDS_PERF_ID);

        /* Use scan interval as timeout (seconds * 1000 = milliseconds) */
        status = CFE_SB_ReceiveBuffer((CFE_SB_Buffer_t **)&IDS_AppData.MsgPtr,
                                       IDS_AppData.CmdPipe,
                                       IDS_AppData.scanInterval * 1000);

        CFE_ES_PerfLogEntry(IDS_PERF_ID);

        if (status == CFE_SUCCESS)
        {
            IDS_ProcessCommandPacket();
        }

        /* Scan on every wakeup (timeout or after processing a command) */
        IDS_ScanFiles();
        IDS_ReportHousekeeping();
    }

    CFE_ES_PerfLogExit(IDS_PERF_ID);
    CFE_ES_ExitApp(IDS_AppData.RunStatus);
}

int32 IDS_AppInit(void)
{
    int32 status;

    IDS_AppData.RunStatus = CFE_ES_RunStatus_APP_RUN;
    IDS_AppData.scanInterval = IDS_SCAN_INTERVAL_DEFAULT;

    status = CFE_EVS_Register(NULL, 0, CFE_EVS_EventFilter_BINARY);
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_CreatePipe(&IDS_AppData.CmdPipe, IDS_PIPE_DEPTH, "IDS_CMD_PIPE");
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_Subscribe(CFE_SB_ValueToMsgId(IDS_CMD_MID), IDS_AppData.CmdPipe);
    if (status != CFE_SUCCESS) return status;

    status = CFE_SB_Subscribe(CFE_SB_ValueToMsgId(IDS_REQ_HK_MID), IDS_AppData.CmdPipe);
    if (status != CFE_SUCCESS) return status;

    CFE_MSG_Init(CFE_MSG_PTR(IDS_AppData.hk.TlmHeader),
                 CFE_SB_ValueToMsgId(IDS_HK_TLM_MID),
                 IDS_HK_TLM_LNGTH);

    /* Initialize counters */
    IDS_AppData.hk.cmdCount = 0;
    IDS_AppData.hk.cmdErrCount = 0;
    IDS_AppData.hk.modifyCount = 0;
    IDS_AppData.hk.accessCount = 0;
    IDS_AppData.hk.missingCount = 0;
    IDS_AppData.hk.scanInterval = IDS_AppData.scanInterval;
    IDS_AppData.hk.filesMonitored = 0;
    memset(IDS_AppData.hk.lastAlert, 0, sizeof(IDS_AppData.hk.lastAlert));

    /* Load canary file list and compute baselines */
    IDS_LoadCanaryList();

    /* Create canary files if they don't exist (honeypots) */
    {
        /* Ensure data directory exists */
        mkdir("data", 0755);

        uint32 ci;
        for (ci = 0; ci < IDS_AppData.fileCount; ci++)
        {
            struct stat cst;
            if (stat(IDS_AppData.files[ci].path, &cst) != 0)
            {
                FILE *cf = fopen(IDS_AppData.files[ci].path, "w");
                if (cf)
                {
                    if (strstr(IDS_AppData.files[ci].path, "encryption.key"))
                    {
                        fprintf(cf, "# SATCOM Link Encryption Key - DO NOT MODIFY\n");
                        fprintf(cf, "ALG: AES-256-GCM\n");
                        fprintf(cf, "KEY: 7A4F2E8C1B9D5F3A6E0C4B8D2F7A1E9C3B5D8F0A2E6C4B9D1F3A7E5C8B0D2F\n");
                        fprintf(cf, "IV:  A3F7C1E9B5D2804F\n");
                        fprintf(cf, "EPOCH: 2026-001T00:00:00Z\n");
                        fprintf(cf, "ROTATE: 2026-180T00:00:00Z\n");
                    }
                    else if (strstr(IDS_AppData.files[ci].path, "startracker.map"))
                    {
                        fprintf(cf, "# Star Tracker Calibration Map v3.2\n");
                        fprintf(cf, "# Format: StarID RA(deg) DEC(deg) Magnitude Pixel_X Pixel_Y\n");
                        fprintf(cf, "VEGA      279.2345  38.7837  0.03  512.4  384.1\n");
                        fprintf(cf, "SIRIUS    101.2872 -16.7161 -1.46  128.9  601.3\n");
                        fprintf(cf, "CANOPUS   095.9880 -52.6957 -0.74  256.7  712.8\n");
                        fprintf(cf, "ARCTURUS  213.9153  19.1824 -0.05  640.2  298.5\n");
                        fprintf(cf, "RIGEL     078.6345 -08.2016  0.13  384.1  544.9\n");
                        fprintf(cf, "PROCYON   114.8274  05.2250  0.34  448.6  467.2\n");
                        fprintf(cf, "BETELGEUS 088.7930  07.4071  0.50  401.3  451.8\n");
                        fprintf(cf, "# Checksum: 0xA3F7\n");
                    }
                    else if (strstr(IDS_AppData.files[ci].path, "gold.os"))
                    {
                        fprintf(cf, "\x7F" "ELF");  /* ELF magic bytes */
                        fprintf(cf, "# GOLD Master OS Image - Recovery Partition\n");
                        fprintf(cf, "# Version: cFS 7.0.1-nos3 (baseline)\n");
                        fprintf(cf, "# SHA256: e3b0c44298fc1c149afbf4c8996fb924\n");
                        fprintf(cf, "#         27ae41e4649b934ca495991b7852b855\n");
                        fprintf(cf, "# Built: 2026-01-15T08:30:00Z\n");
                        fprintf(cf, "# DO NOT MODIFY - Used for safe-mode recovery\n");
                    }
                    else
                    {
                        fprintf(cf, "CANARY\n");
                    }
                    fclose(cf);
                }
            }
        }
    }

    IDS_Baseline();

    /* Log startup status to ids_log */
    {
        char log_buf[256];
        char cwd[128];
        if (getcwd(cwd, sizeof(cwd)) == NULL)
            strncpy(cwd, "(unknown)", sizeof(cwd));

        snprintf(log_buf, sizeof(log_buf), "INIT: CWD=%s, files=%d", cwd, (int)IDS_AppData.fileCount);
        IDS_LogWrite(log_buf);

        uint32 di;
        for (di = 0; di < IDS_AppData.fileCount; di++)
        {
            struct stat dst;
            int accessible = (stat(IDS_AppData.files[di].path, &dst) == 0);
            snprintf(log_buf, sizeof(log_buf), "  [%d] %s -> %s mtime=%u crc=%08X",
                     (int)di, IDS_AppData.files[di].path,
                     accessible ? "OK" : "MISSING",
                     (unsigned)IDS_AppData.files[di].mtime,
                     (unsigned)IDS_AppData.files[di].crc);
            IDS_LogWrite(log_buf);
        }
    }

    CFE_EVS_SendEvent(IDS_STARTUP_INF_EID, CFE_EVS_EventType_INFORMATION,
        "IDS: Initialized. Monitoring %d files, interval=%ds",
        (int)IDS_AppData.fileCount, (int)IDS_AppData.scanInterval);

    IDS_LogWrite("IDS initialized");

    return CFE_SUCCESS;
}

void IDS_LoadCanaryList(void)
{
    osal_id_t fd;
    int32 status;
    char line[IDS_PATH_LEN];
    int idx = 0;
    int line_pos = 0;
    char ch;
    int32 bytes_read;

    IDS_AppData.fileCount = 0;
    memset(IDS_AppData.files, 0, sizeof(IDS_AppData.files));

    status = OS_OpenCreate(&fd, IDS_CANARY_LIST_PATH, OS_FILE_FLAG_NONE, OS_READ_ONLY);
    if (status != OS_SUCCESS)
    {
        CFE_EVS_SendEvent(IDS_CANARY_ERR_EID, CFE_EVS_EventType_ERROR,
            "IDS: Failed to open canary list at %s (err=%d)", IDS_CANARY_LIST_PATH, (int)status);
        return;
    }

    while (idx < IDS_MAX_FILES)
    {
        bytes_read = OS_read(fd, &ch, 1);
        if (bytes_read <= 0) break;

        if (ch == '\n' || ch == '\r')
        {
            if (line_pos > 0)
            {
                line[line_pos] = '\0';
                if (line[0] != '#')
                {
                    strncpy(IDS_AppData.files[idx].path, line, IDS_PATH_LEN - 1);
                    IDS_AppData.files[idx].path[IDS_PATH_LEN - 1] = '\0';
                    idx++;
                }
                line_pos = 0;
            }
        }
        else
        {
            if (line_pos < IDS_PATH_LEN - 1)
            {
                line[line_pos++] = ch;
            }
        }
    }
    /* Handle last line without newline */
    if (line_pos > 0 && idx < IDS_MAX_FILES)
    {
        line[line_pos] = '\0';
        if (line[0] != '#')
        {
            strncpy(IDS_AppData.files[idx].path, line, IDS_PATH_LEN - 1);
            idx++;
        }
    }

    OS_close(fd);
    IDS_AppData.fileCount = idx;

    CFE_EVS_SendEvent(IDS_CANARY_LOAD_EID, CFE_EVS_EventType_INFORMATION,
        "IDS: Loaded %d canary files from list", idx);
}

void IDS_Baseline(void)
{
    uint32 i;
    struct stat st;

    for (i = 0; i < IDS_AppData.fileCount; i++)
    {
        if (stat(IDS_AppData.files[i].path, &st) == 0)
        {
            IDS_AppData.files[i].exists = 1;
            IDS_AppData.files[i].mtime = (uint32)st.st_mtime;
            IDS_AppData.files[i].crc = IDS_ComputeFileCRC(IDS_AppData.files[i].path);
            /* Re-read atime AFTER CRC computation (reading the file updates atime) */
            if (stat(IDS_AppData.files[i].path, &st) == 0)
            {
                IDS_AppData.files[i].atime = (uint32)st.st_atime;
            }
        }
        else
        {
            IDS_AppData.files[i].exists = 0;
            IDS_AppData.files[i].mtime = 0;
            IDS_AppData.files[i].atime = 0;
            IDS_AppData.files[i].crc = 0;
        }
    }

    IDS_AppData.hk.filesMonitored = IDS_AppData.fileCount;
}

void IDS_ScanFiles(void)
{
    uint32 i;
    struct stat st;
    uint32 current_crc;
    char log_buf[128];
    static uint32 scan_count = 0;
    scan_count++;

    /* Log every 6th scan (~once per minute at 10s interval) */
    if (scan_count % 6 == 1)
    {
        snprintf(log_buf, sizeof(log_buf), "SCAN #%u: checking %d files", (unsigned)scan_count, (int)IDS_AppData.fileCount);
        IDS_LogWrite(log_buf);
    }

    for (i = 0; i < IDS_AppData.fileCount; i++)
    {
        if (stat(IDS_AppData.files[i].path, &st) != 0)
        {
            /* File is missing */
            if (IDS_AppData.files[i].exists)
            {
                IDS_AppData.hk.missingCount++;
                strncpy(IDS_AppData.hk.lastAlert, IDS_AppData.files[i].path,
                        sizeof(IDS_AppData.hk.lastAlert) - 1);

                CFE_EVS_SendEvent(IDS_ALERT_MISSING_EID, CFE_EVS_EventType_CRITICAL,
                    "IDS: CANARY FILE MISSING '%s'", IDS_AppData.files[i].path);

                snprintf(log_buf, sizeof(log_buf), "MISSING: %s", IDS_AppData.files[i].path);
                IDS_LogWrite(log_buf);

                IDS_AppData.files[i].exists = 0;
            }
            continue;
        }

        /* Check for modification (mtime or CRC change) */
        if ((uint32)st.st_mtime != IDS_AppData.files[i].mtime)
        {
            current_crc = IDS_ComputeFileCRC(IDS_AppData.files[i].path);
            if (current_crc != IDS_AppData.files[i].crc)
            {
                IDS_AppData.hk.modifyCount++;
                strncpy(IDS_AppData.hk.lastAlert, IDS_AppData.files[i].path,
                        sizeof(IDS_AppData.hk.lastAlert) - 1);

                CFE_EVS_SendEvent(IDS_ALERT_MODIFIED_EID, CFE_EVS_EventType_CRITICAL,
                    "IDS: CANARY MODIFIED '%s' (CRC %08X→%08X)",
                    IDS_AppData.files[i].path,
                    (unsigned)IDS_AppData.files[i].crc, (unsigned)current_crc);

                snprintf(log_buf, sizeof(log_buf), "MODIFIED: %s crc=%08X->%08X",
                         IDS_AppData.files[i].path,
                         (unsigned)IDS_AppData.files[i].crc, (unsigned)current_crc);
                IDS_LogWrite(log_buf);

                /* Update baseline to avoid repeated alerts */
                IDS_AppData.files[i].crc = current_crc;
                IDS_AppData.files[i].mtime = (uint32)st.st_mtime;
            }
            else
            {
                /* mtime changed but CRC same (touch without content change) */
                IDS_AppData.files[i].mtime = (uint32)st.st_mtime;
            }
        }

        /* Check for access (atime change) */
        if ((uint32)st.st_atime != IDS_AppData.files[i].atime)
        {
            IDS_AppData.hk.accessCount++;
            strncpy(IDS_AppData.hk.lastAlert, IDS_AppData.files[i].path,
                    sizeof(IDS_AppData.hk.lastAlert) - 1);

            CFE_EVS_SendEvent(IDS_ALERT_ACCESSED_EID, CFE_EVS_EventType_ERROR,
                "IDS: CANARY ACCESSED '%s'", IDS_AppData.files[i].path);

            snprintf(log_buf, sizeof(log_buf), "ACCESSED: %s", IDS_AppData.files[i].path);
            IDS_LogWrite(log_buf);

            /* Update atime baseline */
            IDS_AppData.files[i].atime = (uint32)st.st_atime;
        }

        /* Mark as existing if it was previously missing and reappeared */
        if (!IDS_AppData.files[i].exists)
        {
            IDS_AppData.files[i].exists = 1;
            IDS_AppData.files[i].mtime = (uint32)st.st_mtime;
            IDS_AppData.files[i].atime = (uint32)st.st_atime;
            IDS_AppData.files[i].crc = IDS_ComputeFileCRC(IDS_AppData.files[i].path);
        }
    }
}

static uint32 IDS_ComputeFileCRC(const char *path)
{
    FILE *fp;
    uint8 buf[512];
    size_t bytes_read;
    uint32 crc = 0;

    fp = fopen(path, "rb");
    if (fp == NULL)
    {
        return 0;
    }

    while ((bytes_read = fread(buf, 1, sizeof(buf), fp)) > 0)
    {
        uint32 i;
        for (i = 0; i < (uint32)bytes_read; i++)
        {
            crc = ((crc << 5) + crc) + buf[i]; /* djb2 hash */
        }
    }

    fclose(fp);
    return crc;
}

void IDS_LogWrite(const char *msg)
{
    struct stat st;
    FILE *fp;
    time_t now;
    struct tm *tm_info;
    char ts[32];

    /* Check if rotation needed */
    if (stat(IDS_LOG_PATH, &st) == 0)
    {
        if (st.st_size >= IDS_LOG_MAX_SIZE)
        {
            IDS_LogRotate();
        }
    }

    fp = fopen(IDS_LOG_PATH, "a");
    if (fp == NULL)
    {
        return;
    }

    now = time(NULL);
    tm_info = gmtime(&now);
    strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", tm_info);

    fprintf(fp, "[%s] %s\n", ts, msg);
    fclose(fp);
}

static void IDS_LogRotate(void)
{
    /* Remove old backup and rename current to old */
    remove(IDS_LOG_OLD_PATH);
    rename(IDS_LOG_PATH, IDS_LOG_OLD_PATH);
}

void IDS_ProcessCommandPacket(void)
{
    CFE_SB_MsgId_t msgId = CFE_SB_INVALID_MSG_ID;
    CFE_MSG_GetMsgId(IDS_AppData.MsgPtr, &msgId);

    switch (CFE_SB_MsgIdToValue(msgId))
    {
        case IDS_CMD_MID:
            IDS_ProcessGroundCommand();
            break;
        case IDS_REQ_HK_MID:
            IDS_ReportHousekeeping();
            break;
        default:
            IDS_AppData.hk.cmdErrCount++;
            break;
    }
}

void IDS_ProcessGroundCommand(void)
{
    CFE_MSG_FcnCode_t cmdCode = 0;
    CFE_MSG_GetFcnCode(IDS_AppData.MsgPtr, &cmdCode);

    switch (cmdCode)
    {
        case IDS_NOOP_CC:
            IDS_AppData.hk.cmdCount++;
            CFE_EVS_SendEvent(IDS_CMD_NOOP_EID, CFE_EVS_EventType_INFORMATION,
                "IDS: NOOP - monitoring %d files, %d modifications, %d accesses",
                (int)IDS_AppData.fileCount,
                (int)IDS_AppData.hk.modifyCount,
                (int)IDS_AppData.hk.accessCount);
            break;

        case IDS_RESET_CC:
            IDS_AppData.hk.cmdCount = 0;
            IDS_AppData.hk.cmdErrCount = 0;
            IDS_AppData.hk.modifyCount = 0;
            IDS_AppData.hk.accessCount = 0;
            IDS_AppData.hk.missingCount = 0;
            memset(IDS_AppData.hk.lastAlert, 0, sizeof(IDS_AppData.hk.lastAlert));
            CFE_EVS_SendEvent(IDS_CMD_RESET_EID, CFE_EVS_EventType_INFORMATION,
                "IDS: Counters reset");
            IDS_LogWrite("Counters reset by command");
            break;

        case IDS_REBASELINE_CC:
            IDS_AppData.hk.cmdCount++;
            IDS_Baseline();
            CFE_EVS_SendEvent(IDS_REBASELINE_EID, CFE_EVS_EventType_INFORMATION,
                "IDS: Rebaselined %d files", (int)IDS_AppData.fileCount);
            IDS_LogWrite("Rebaseline performed by command");
            break;

        case IDS_SET_INTERVAL_CC:
        {
            IDS_SetIntervalCmd_t *cmd = (IDS_SetIntervalCmd_t *)IDS_AppData.MsgPtr;
            if (cmd->interval >= 1)
            {
                IDS_AppData.scanInterval = cmd->interval;
                IDS_AppData.hk.scanInterval = cmd->interval;
                IDS_AppData.hk.cmdCount++;
                CFE_EVS_SendEvent(IDS_CMD_NOOP_EID, CFE_EVS_EventType_INFORMATION,
                    "IDS: Scan interval set to %d seconds", cmd->interval);
            }
            else
            {
                IDS_AppData.hk.cmdErrCount++;
            }
            break;
        }

        default:
            IDS_AppData.hk.cmdErrCount++;
            CFE_EVS_SendEvent(IDS_CMD_ERR_EID, CFE_EVS_EventType_ERROR,
                "IDS: Invalid command code %d", cmdCode);
            break;
    }
}

void IDS_ReportHousekeeping(void)
{
    IDS_AppData.hk.scanInterval = IDS_AppData.scanInterval;
    IDS_AppData.hk.filesMonitored = IDS_AppData.fileCount;
    CFE_SB_TimeStampMsg((CFE_MSG_Message_t *)&IDS_AppData.hk);
    CFE_SB_TransmitMsg((CFE_MSG_Message_t *)&IDS_AppData.hk, true);
}
