import threading
import socket
from scapy.all import *
import sys

class CloakingDevice:
    def __init__(self, telemetry_port=5013, forward_ip="10.10.20.10", packet_limit=100):
        self.telemetry_port = telemetry_port
        self.forward_ip = forward_ip
        self.packet_limit = packet_limit
        self._stop_event = threading.Event()
        self.received_packets = []
        self.status = "Deactivated"
        self.listener_thread = None
        self.forwarder_thread = None

    def activate(self, app):
        # Prevent multiple activations
        if self.listener_thread and self.listener_thread.is_alive():
            print("Cloaking device is already active. Ignoring duplicate start.")
            return

        self._stop_event.clear()
        self.received_packets = []  # Clear old data
        self.listener_thread = threading.Thread(target=self._activate, args=(app,))
        self.listener_thread.daemon = True
        self.listener_thread.start()
        self.status = "Activated"

    def _activate(self, app):
        sys.stdout.flush()
        with app.app_context():
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.bind(('0.0.0.0', self.telemetry_port))
                sock.settimeout(1.0)
                print(f"Listening for packets on 0.0.0.0:{self.telemetry_port}...")
            except Exception as e:
                print(f"Failed to bind socket on port {self.telemetry_port}: {e}")
                self.status = "error"
                return

            while not self._stop_event.is_set() and len(self.received_packets) < self.packet_limit:
                try:
                    data, addr = sock.recvfrom(1024)
                    self.store_packet(data, addr)
                except socket.timeout:
                    continue
                except Exception as e:
                    print(f"Error receiving packet: {e}")
                    break

            sock.close()

            if len(self.received_packets) >= self.packet_limit:
                self.status = "sending_packets"
                print("Received 100 packets, starting to forward in a loop...")
                self.forwarder_thread = threading.Thread(target=self.forward_packets_loop)
                self.forwarder_thread.daemon = True
                self.forwarder_thread.start()

    def store_packet(self, data, addr):
        self.received_packets.append((data, addr))
        print(f"Packet received from {addr[0]}:{addr[1]} - Total packets: {len(self.received_packets)}")

    def forward_packets_loop(self):
        while not self._stop_event.is_set():
            print("Restarting the send loop")
            sys.stdout.flush()
            for data, addr in self.received_packets:
                if not self._stop_event.is_set():
                    src_ip = addr[0]
                    src_port = addr[1]
                    dst_ip = self.forward_ip
                    dst_port = self.telemetry_port

                    ip_header = IP(src='10.10.20.20', dst=dst_ip)
                    udp_header = UDP(sport=src_port, dport=dst_port)
                    packet = ip_header / udp_header / data
                    try:
                        send(packet, verbose=0)
                        #print(f"Forwarded packet from {src_ip} to {dst_ip}")
                    except Exception as e:
                        print(f"Error forwarding packet: {e}")
                else:
                    print("Stop event is set")
                    sys.stdout.flush()
        print("I am done sending now")
        sys.stdout.flush()

    def deactivate(self):
        if not self.listener_thread:
            print("Cloaking device was never started.")
            return
        if not self.listener_thread.is_alive():
            print("Cloaking device is already stopped.")
            if not self._stop_event.is_set():
                self._stop_event.set()
            sys.stdout.flush()
            self.status = "Deactivated"
            return

        print("Cloaking device is alive - proceeding to stop")
        sys.stdout.flush()
        self._stop_event.set()

        # Wait for listener thread to finish
        self.listener_thread.join(timeout=5)

        # Wait for forwarder thread to finish, if it was started
        if self.forwarder_thread and self.forwarder_thread.is_alive():
            self.forwarder_thread.join(timeout=5)

        self.status = "Deactivated"
        print("Cloaking device deactivated.")
        sys.stdout.flush()

        # if not self.listener_thread:
        #     print("Cloaking device was never started.")
        #     return
        # if not self.listener_thread.is_alive():
        #     print("Cloaking device is already stopped.")
        #     return

        # self._stop_event.set()
        # self.listener_thread.join(timeout=5)
        # self.status = "Deactivated"
        # print("Cloaking device deactivated.")
