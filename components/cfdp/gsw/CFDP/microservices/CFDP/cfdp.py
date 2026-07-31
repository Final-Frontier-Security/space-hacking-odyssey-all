import os
import time
from datetime import datetime, timezone
from openc3.microservices.microservice import Microservice
from openc3.utilities.sleeper import Sleeper
from openc3.api import *

LOG_PATH = "/microservice_logs/cfdp.log"


def log(msg):
    ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{ts}] {msg}"
    try:
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        with open(LOG_PATH, "a") as f:
            f.write(line + "\n")
    except Exception:
        pass


class CFDP(Microservice):
    def __init__(self, name):
        super().__init__(name)
        self.TARGET_NAME = "CFDP"
        self.TLM_PACKET_NAME = "DOWNLINK_FILE_PKT"
        self.CMD_PACKET_NAME = "UPLOAD_TO_SATELLITE_DATA"
        self.period = 2
        self.sleeper = Sleeper()
        self.CHUNK_SIZE = 256
        self.past_data_recv = ""
        self.past_data_send = ""
        self.sending = False
        self.sending_num = 0
        self.upload_complete = False
        log("CFDP microservice starting")

    def run(self):
        self.sleeper.sleep(self.period)
        log("CFDP microservice run loop started")
        while True:
            if self.cancel_thread:
                break
            try:
                data = tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} FILE_DATA")
                filename_dst = tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} FILENAME_DST")
                filename_src = tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} FILENAME_SRC")
                pdu = tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} PDU_TYPE")
                direction = tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} DIRECTION")
                log(f"POLL: direction={direction} pdu={pdu} dst='{filename_dst}' src='{filename_src}' data_len={len(data) if data else 0}")
            except Exception as e:
                log(f"ERROR reading telemetry: {e}")
                self.sleeper.sleep(self.period)
                continue

            # Skip if no telemetry has arrived yet
            if filename_dst is None or filename_src is None or direction is None:
                self.sleeper.sleep(self.period)
                continue

            # Reset upload lock when direction changes
            if direction != 2:
                self.upload_complete = False

            if filename_dst is not None and filename_src is not None and direction is not None:
                if pdu != 2:
                    if direction == 1:
                        # Download: satellite is sending file data to ground
                        if data != "" and data is not None:
                            log(f"DOWNLOAD receiving chunk for '{filename_dst}' (len={len(data) if data else 0})")
                            try:
                                with open(os.path.join("/received_files", filename_dst.strip()), "ab") as f:
                                    if type(data) != bytes:
                                        f.write(data.encode())
                                    else:
                                        f.write(data)
                            except Exception as e:
                                log(f"ERROR writing received file: {e}")
                    if direction == 2 and not self.upload_complete:
                        # Upload: ground needs to send file to satellite
                        self.sending_num = 0
                        self.sending = True
                        src_path = os.path.join("/send_files", filename_dst.strip())
                        log(f"UPLOAD starting: source='{src_path}' destination='{filename_src}'")
                        try:
                            with open(src_path, "rb") as file:
                                while self.sending:
                                    data = file.read(self.CHUNK_SIZE)
                                    if data:
                                        data = data.hex()
                                        bytesRead = len(data)
                                        try:
                                            cmd(f"{self.TARGET_NAME} {self.CMD_PACKET_NAME} with LENGTH {bytesRead}, PDU 1, DESTINATION '{filename_src}', FILE_DATA '{data}'")
                                            log(f"UPLOAD chunk {self.sending_num}: {bytesRead} hex bytes sent")
                                        except Exception as cmd_err:
                                            log(f"UPLOAD chunk {self.sending_num} FAILED (retrying): {cmd_err}")
                                            time.sleep(2)
                                            try:
                                                cmd(f"{self.TARGET_NAME} {self.CMD_PACKET_NAME} with LENGTH {bytesRead}, PDU 1, DESTINATION '{filename_src}', FILE_DATA '{data}'")
                                                log(f"UPLOAD chunk {self.sending_num}: retry succeeded")
                                            except Exception as retry_err:
                                                log(f"UPLOAD chunk {self.sending_num} RETRY FAILED: {retry_err}")
                                        time.sleep(1)
                                        self.sending_num += 1
                                    else:
                                        self.sending = False
                            log(f"UPLOAD sending EOF to satellite")
                            cmd(f"{self.TARGET_NAME} {self.CMD_PACKET_NAME} with LENGTH 0, PDU 2, DESTINATION '{filename_src}', FILE_DATA ''")
                            set_tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} DIRECTION = 99")
                            self.upload_complete = True
                            log(f"UPLOAD complete: '{filename_dst}' uploaded as '{filename_src}'")
                        except FileNotFoundError:
                            log(f"ERROR upload file not found: {src_path}")
                        except Exception as e:
                            log(f"ERROR during upload: {e}")
                elif direction != 99:
                    set_tlm(f"{self.TARGET_NAME} {self.TLM_PACKET_NAME} DIRECTION = 99")
                    log(f"DOWNLOAD complete: '{filename_dst}'")

            self.sleeper.sleep(self.period)

    def shutdown(self):
        log("CFDP microservice shutting down")
        self.sleeper.cancel()
        super().shutdown()


if __name__ == "__main__":
    CFDP.class_run()
