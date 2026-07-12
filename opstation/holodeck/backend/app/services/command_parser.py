import zipfile
import io

def extract_config_files(file):
    configs = {}
    with zipfile.ZipFile(io.BytesIO(file.read()), 'r') as zip_file:
        config_files = [f for f in zip_file.namelist() if 'cmd_tlm' in f and f.endswith('.txt') and "cfdp" not in f and "PDU" not in f and "_cmd" in f.lower()]
        for config_file in config_files:
            print(config_file)
            with zip_file.open(config_file) as file:
                target_name = config_file.split('/')[-1].split('.')[0]  # Extract the config file name without extension
                configs[target_name] = parse_config_file(file)
    return configs

def parse_config_file(f):
    config = {}
    command_name = ''
    for line in f:
        print(line)
        print(command_name)
        print(config)
        line = line.decode('utf-8').strip()
        if line.startswith("COMMAND"):
            parts = line.split()
            command_name = parts[2]
            config[command_name] = {
                "endian": parts[3],
                "description": ' '.join(parts[4:]).strip('"').split('"')[0],
                "function_code": 0,
                "parameters": []
            }
        elif line.startswith('APPEND_PARAMETER') or line.startswith('APPEND_ID_PARAMETER'):
            parameter = {
                "name": "",
                "type": "",
                "offset": "",
                "endian": "",
                "states": {},
                "description": "",
                "min": 0,
                "max": 0,
                "default": 0
            }
            parts = line.split()
            parameter["name"] = parts[1]
            parameter['type'] = parts[3]
            parameter['offset'] = parts[2]
            parameter['endian'] = parts[-1] if "ENDIAN" in parts[-1] else "BIG_ENDIAN"

            #set the function code and stream id on the command config
            if parameter["name"] == "CCSDS_FC":
                config[command_name]['function_code'] = parts[6]
            elif parameter["name"] == "CCSDS_STREAMID":
                config[command_name]['stream_id'] = parts[6]

            if parameter['type'] in ["STRING","BLOCK"]:
                parameter['default'] = parts[4].strip('"')
                parameter['description'] = ' '.join(parts[5:]).strip('"').split('"')[0]
            else:
                parameter['min'] = parts[4]
                parameter['max'] = parts[5]
                parameter['default'] = parts[6]
                parameter['description'] = ' '.join(parts[7:]).strip('"').split('"')[0]
            config[command_name]['parameters'].append(parameter)
        elif line.startswith("STATE"):
            parts = line.split()
            state_name = parts[1]
            state_value = parts[2]
            config[command_name]["parameters"][-1]['states'][state_name] = state_value
        elif len(line) > 1 and "#" not in line:
            print("NONSTANDARD")
            print(line)
    return config
