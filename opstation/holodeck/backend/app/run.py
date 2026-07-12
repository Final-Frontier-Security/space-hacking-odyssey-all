from flask import Flask, request, jsonify
from flask_migrate import Migrate
from models import db, Target, Command, CommandParameter, InterceptedCommand, InterceptedCommandParameter, Setting
from services import command_parser, command_sender, command_interceptor, cloaking_device
from sqlalchemy.orm import aliased, joinedload
from flask_cors import CORS

import os
import logging
from logging.handlers import RotatingFileHandler

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///holodeck.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
CORS(app, resources={r'/*': {'origins': '*'}})

# Logging setup - 5MB max, 3 backup files
log_handler = RotatingFileHandler('holodeck.log', maxBytes=5*1024*1024, backupCount=3)
log_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
log_handler.setLevel(logging.INFO)
app.logger.addHandler(log_handler)
app.logger.setLevel(logging.INFO)

# DB setup
db.init_app(app)
migrate = Migrate(app, db)

# Constants
satellite_ip = '10.10.10.10'
groundstation_ip = '10.10.20.10'
command_port = 5012
telemetry_port = 5013

# Services
interceptor = command_interceptor.Interceptor(command_port)
cloak = cloaking_device.CloakingDevice(telemetry_port=telemetry_port, forward_ip=groundstation_ip)

@app.route("/api/target", methods=['GET'])
def get_targets():
    targets = Target.query.all()
    return jsonify([target.to_dict() for target in targets])

@app.route("/api/target/<int:target_id>", methods=['GET'])
def get_target(target_id):
    target = Target.query.get_or_404(target_id)
    return jsonify(target)

@app.route("/api/target/<int:target_id>/command/<int:command_id>", methods=['GET'])
def get_target_command(target_id, command_id):
    target = Target.query.options(joinedload(Target.commands)).filter_by(id=target_id).first_or_404()
    command = Command.query.options(joinedload(Command.parameters)).filter_by(target_id=target.id, id=command_id).first_or_404()
    return jsonify({'target': target, 'command': command})

@app.route("/api/target/<int:target_id>/command/<int:command_id>/execute", methods=["POST"])
def execute_command(target_id, command_id):
    try:
        target = Target.query.filter_by(id=target_id).first()
        command = Command.query.filter_by(id=command_id).first()
        parameters = command.parameters
        request_data = request.get_json()
        for request_parameter in request_data:
            for parameter in parameters:
                if parameter.name == request_parameter["name"] and "CCSDS" not in parameter.name:
                    parameter.default = request_parameter["default"]
        command_packet = command_sender.create_command_packet(target, command, parameters)
        command_sender.send_command_packet(satellite_ip, 5012, command_packet)
        app.logger.info(f"Command executed: {target.name}/{command.name}")
        return jsonify("Sent Successfully")
    except Exception as e:
        app.logger.error(f"Command execution failed: {e}")
        return jsonify({"error": "Command failed to execute"}), 500

@app.route("/api/interceptor/start", methods=["POST"])
def start_interceptor():
    try:
        interceptor.start(app)
        app.logger.info("Interceptor started")
        return jsonify("Interceptor started")
    except Exception as e:
        app.logger.error(f"Interceptor failed to start: {e}")
        return jsonify({"error": "Interceptor failed to start"}), 500

@app.route("/api/interceptor/stop", methods=["POST"])
def stop_interceptor():
    try:
        interceptor.stop()
        app.logger.info("Interceptor stopped")
        return jsonify("Interceptor stopped")
    except Exception as e:
        app.logger.error(f"Interceptor failed to stop: {e}")
        return jsonify({"error": "Interceptor failed to stop"}), 500

@app.route("/api/interceptor/status", methods=["GET"])
def get_interceptor_status():
    return jsonify({"status": interceptor.status})

@app.route("/api/interceptor/command", methods=["GET"])
def intercepted_commands():
    intercepted_commands = InterceptedCommand.query.all()
    return jsonify([intercepted_command.to_dict() for intercepted_command in intercepted_commands])

@app.route("/api/interceptor/command/<int:intercepted_command_id>", methods=["GET"])
def intercepted_command(intercepted_command_id):
    intercepted_command = InterceptedCommand.query.get_or_404(intercepted_command_id)
    command = intercepted_command.command
    target = command.target
    icp = aliased(InterceptedCommandParameter)
    cp = aliased(CommandParameter)
    query = db.session.query(icp, cp).join(cp, icp.base_parameter_id == cp.id)
    results = query.all()
    return jsonify({
        "target": target.as_dict(),
        "command": command.as_dict(),
        "parameters": [result[0].as_dict() for result in results]
    })

@app.route("/api/interceptor/clear", methods=["POST"])
def clear_intercepted_commands():
    InterceptedCommand.query.delete()
    InterceptedCommandParameter.query.delete()
    db.session.commit()
    app.logger.info("Intercepted commands cleared")
    return jsonify({"message": "All intercepted commands cleared"})

@app.route("/api/cloak", methods=["GET"])
def cloaking():
    return jsonify({"status": cloak.status, "packet_count": len(cloak.received_packets)})

@app.route("/api/cloak/activate",methods=["POST"])
def enable_cloak():
    try:
        cloak.activate(app)
        app.logger.info("Cloaking device activated")
        return jsonify({"active": True, "status": cloak.status})
    except Exception as e:
        app.logger.error(f"Cloaking device failed to start: {e}")
        return jsonify({"error": "Cloaking device failed to start"}), 500

@app.route("/api/cloak/deactivate",methods=["POST"])
def disable_cloak():
    try:
        cloak.deactivate()
        app.logger.info("Cloaking device deactivated")
        return jsonify({"active": False, "status": cloak.status})
    except Exception as e:
        app.logger.error(f"Cloaking device failed to stop: {e}")
        return jsonify({"error": "Cloaking device failed to stop"}), 500

@app.route("/api/readyroom", methods=["GET"])
def readyroom():
    return jsonify([setting.to_dict() for setting in Setting.query.all()])

@app.route("/api/readyroom", methods=["POST"])
def update_readyroom():
    settings = Setting.query.all()
    for setting in settings:
        if setting.name in request.form:
            setting.value = request.form[setting.name]
    db.session.commit()
    return jsonify("Settings updated")

@app.route('/api/readyroom/cosmos/upload', methods=['POST'])
def upload_file():
    try:
        Target.query.delete()
        Command.query.delete()
        CommandParameter.query.delete()
        setting = Setting.query.filter(Setting.name == 'configs_loaded').first()
        setting.value = 'False'
        db.session.commit()

        if 'file' not in request.files:
            return jsonify({'error': 'No file part'}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No selected file'}), 400

        if file and file.filename.endswith('.zip'):
            configs = command_parser.extract_config_files(file)
            for target_name in configs:
                target = Target.create_from_config(target_name)
                for command_name in configs[target_name]:
                    command = Command.create_from_config(target.id, command_name, configs[target_name][command_name])
                    for command_parameter_config in configs[target_name][command_name]["parameters"]:
                        CommandParameter.create_from_config(command.id, command_parameter_config)
            targets = Target.query.all()
            commands = Command.query.all()
            command_parameters = CommandParameter.query.all()
            app.logger.info(f"Config uploaded: {len(targets)} targets, {len(commands)} commands")
            return jsonify({'success': 'File uploaded', 'targets': len(targets), 'commands': len(commands), 'command_parameters': len(command_parameters)})
        else:
            return jsonify({'error': 'Invalid file type'}), 400
    except Exception as e:
        app.logger.error(f"Config upload failed: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/readyroom/cosmos', methods=['DELETE'])
def delete_cosmos_configs():
    Target.query.delete()
    Command.query.delete()
    CommandParameter.query.delete()
    setting = Setting.query.filter(Setting.name == 'configs_loaded').first()
    setting.value = 'False'
    db.session.commit()
    app.logger.info("COSMOS configurations deleted")
    return jsonify("COSMO configurations deleted")

@app.route('/api/readyroom/command/count', methods=['GET'])
def command_count():
    return jsonify(Command.query.count())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
