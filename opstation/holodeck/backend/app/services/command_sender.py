import socket
import struct

def create_command_packet(target, command, parameters):
    print("Command: " + command.name)
    print("First parameter: " + parameters[0].name)
    print(parameters[1].name)
    print(parameters[2].name)
    user_data = b''
    primary_header = struct.pack('!HHH',
                                int(parameters[0].default, 16), # CCSDS_STREAMID
                                int(parameters[1].default, 16), # CCSDS_SEQUENCE
                                int(parameters[2].default)) # CCSDS_LENGTH
    for parameter in parameters[3:]:
        print(parameter.name)
        print(parameter.default)
        parameter_byte_format = get_parameter_byte_format(parameter)
        user_data = user_data + get_parameter_byte_data(parameter_byte_format, parameter)
    
    return primary_header + user_data

def send_command_packet(satellite_ip, satellite_port, packet):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.sendto(packet, (satellite_ip, satellite_port))
    finally:
        sock.close()

def get_command_byte_format(command):
    byte_formats = []
    for parameter in command.parameters:
        print(parameter.name)
        byte_formats.append(get_parameter_byte_format(parameter))

    return byte_formats

def get_parameter_byte_format(parameter):
    print("Creating struct for parameter: " + parameter.name)
    byte_format = ''

    #Set endianness
    if parameter.endian.upper() == "LITTLE_ENDIAN":
        byte_format += '<'
    else:
        byte_format += '!'

    #Set byte length and type
    if parameter.type == "UINT":
        if parameter.offset == "8":
            byte_format += 'B'
        elif parameter.offset == "16":
            byte_format += 'H'
        elif parameter.offset == "32":
            byte_format += 'I'
        elif parameter.offset == "64":
            byte_format += 'Q'
        elif parameter.offset == "128":
            byte_format += '16s'  # Treat 128-bit as a 16-byte string
    elif parameter.type == "INT":
        if parameter.offset == "8":
            byte_format += 'b'
        elif parameter.offset == "16":
            byte_format += 'h'
        elif parameter.offset == "32":
            byte_format += 'i'
        elif parameter.offset == "64":
            byte_format += 'q'
        elif parameter.offset == "128":
            byte_format += '16s'
    elif parameter.type in ["STRING", "BLOCK"]:
        byte_length = int(parameter.offset) // 8  # Convert bits to bytes
        byte_format += f'{byte_length}s'
        #byte_format += str(int(parameter.offset) / 8) + 's'
    print("Byte format: " + str(byte_format))

    return byte_format

def get_parameter_byte_data(byte_format, parameter):
    #Add data
    print(parameter.default)
    if parameter.type in ["UINT","INT", "BLOCK"]:
        if '0x' in parameter.default:
            data = int(parameter.default, 16)
        else:
            data = int(parameter.default)
    elif parameter.type == "STRING":
        data = parameter.default.encode()
    print("Data: " + str(data))

    return struct.pack(byte_format, data)

