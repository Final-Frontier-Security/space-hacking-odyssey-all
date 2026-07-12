import socket
import struct
from services import command_sender
from models import Command, CommandParameter, InterceptedCommand, InterceptedCommandParameter, db
import threading    

class Interceptor:
    def __init__(self, udp_port):
        self.udp_port = udp_port
        self.is_started = False
        self._stop_event = threading.Event()
        self.status = "Deactivated"
        self.listener_thread = None

    def start(self, app):
        if self.listener_thread and self.listener_thread.is_alive():
            print("Interceptor already running.")
            return
        self._stop_event.clear()
        self.listener_thread = threading.Thread(target=self._start, args=(app,))
        self.listener_thread.daemon = True
        self.listener_thread.start()
        self.is_started = True

    def _start(self, app):
        with app.app_context():
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.bind(('0.0.0.0', self.udp_port))
                sock.settimeout(1.0)
                print(f"Listening for packets on 0.0.0.0:{self.udp_port}...")
                self.status = "Activated"
            except Exception as e:
                print(f"Error binding to UDP port {self.udp_port}: {e}")
                self.status = "error"
                return

            while not self._stop_event.is_set():
                try:
                    data, addr = sock.recvfrom(1024)
                    self.process_packet(data)
                except socket.timeout:
                    continue
                except Exception as e:
                    print(f"Error receiving or processing packet: {e}")
                    continue

    def stop(self):
        if self.listener_thread and self.listener_thread.is_alive():
            self._stop_event.set()
            self.listener_thread.join(timeout=5)
            self.is_started = False
            self.status = "Deactivated"
            print("Interceptor stopped.")
        else:
            print("Interceptor was not running.")

    def process_packet(self, data):
        try:
            ccsds_packet_format = '!HHHBB'
            unpacked_data = struct.unpack(ccsds_packet_format, data[:struct.calcsize(ccsds_packet_format)])

            ccsds_streamid = hex(unpacked_data[0])
            ccsds_streamid = ccsds_streamid[:2] + ccsds_streamid[2:].upper()
            ccsds_function_code = int(unpacked_data[3])
            print("CCSDS Stream: {0}".format(ccsds_streamid))
            print(ccsds_function_code)

            command = Command.query.filter_by(stream_id=ccsds_streamid, function_code=ccsds_function_code).first()
            if not command:
                print(f"No matching command found for Stream ID {ccsds_streamid} FC {ccsds_function_code}")
                return

            command_parameter_byte_formats = command_sender.get_command_byte_format(command)

            byte_offset = 0
            intercepted_data = []
            for parameter_byte_format in command_parameter_byte_formats:
                intercepted_data.append(struct.unpack_from(parameter_byte_format, data, byte_offset)[0])
                byte_offset += struct.calcsize(parameter_byte_format)

            print(intercepted_data)
            self.create_intercepted_command_parameters(command, intercepted_data)

        except Exception as e:
            print(f"process_packet error: {e}")

    def create_intercepted_command_parameters(self, command, intercepted_data):
        intercepted_command = InterceptedCommand(base_command_id=command.id)
        db.session.add(intercepted_command)
        db.session.commit()

        print("Intercepted data: {0}".format(intercepted_data))

        for parameter, intercepted_value in zip(command.parameters, intercepted_data):
            if parameter.type in ["STRING", "BLOCK"]:
                try:
                    intercepted_value = intercepted_value.decode("utf-8").rstrip('\x00')
                except Exception:
                    intercepted_value = "<decode error>"

            print("Value: {0}".format(intercepted_value))
            intercepted_param = InterceptedCommandParameter(
                intercepted_command_id=intercepted_command.id,
                base_parameter_id=parameter.id,
                value=self.format_parameter_value(intercepted_value, parameter)
            )
            db.session.add(intercepted_param)
            db.session.commit()

    def format_parameter_value(self, intercepted_parameter_value, parameter):
        if parameter.default.startswith('0x'):
            return '0x' + hex(int(intercepted_parameter_value))[2:].upper()
        return intercepted_parameter_value
