from flask_sqlalchemy import SQLAlchemy
import json

db = SQLAlchemy()

class Setting(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    value = db.Column(db.String(100), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'value': self.value
        }

    @staticmethod
    def get_setting(name):
        setting = Setting.query.filter_by(name=name).first()

        if setting is None:
            return None

        return setting.value

    @staticmethod
    def set_setting(name, value):
        setting = Setting.query.filter_by(name=name).first()

        if setting is None:
            setting = Setting(name=name, value=value)
            db.session.add(setting)
        else:
            setting.value = value

        db.session.commit()

        return setting

class Target(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    commands = db.relationship('Command', backref='target')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'commands': [command.to_dict() for command in self.commands]
        }

    @staticmethod
    def create_from_config(target_name):
        target = Target(name=target_name)
        
        db.session.add(target)
        db.session.commit()

        return target

class Command(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    target_id = db.Column(db.Integer, db.ForeignKey('target.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    endian = db.Column(db.String(100), nullable=False)
    stream_id = db.Column(db.String(100), nullable=True)
    function_code = db.Column(db.Integer, nullable=True)
    description = db.Column(db.String(200), nullable=True)
    parameters = db.relationship('CommandParameter', order_by="CommandParameter.id.asc()", backref='command')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'endian': self.endian,
            'stream_id': self.stream_id,
            'function_code': self.function_code,
            'description': self.description,
            'parameters': [parameter.to_dict() for parameter in self.parameters],
            'target': {
                'id': self.target.id,
                'name': self.target.name
            }
        }
    
    @staticmethod
    def create_from_config(target_id, command_name, config):
        command = Command(target_id=target_id, name=command_name, endian=config["endian"], description=config["description"], function_code=config['function_code'], stream_id=config['stream_id'])

        db.session.add(command)
        db.session.commit()

        return command

class CommandParameter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    command_id = db.Column(db.Integer, db.ForeignKey('command.id'), nullable=False)
    name = db.Column(db.String(256), nullable=False)
    default = db.Column(db.String(256), nullable=False)
    min = db.Column(db.String(256), nullable=True)
    max = db.Column(db.String(256), nullable=True)
    states = db.Column(db.String(256), nullable=True)
    type = db.Column(db.String(256), nullable=False)
    offset = db.Column(db.String(256), nullable=False)
    endian = db.Column(db.String(256), nullable=False)
    description = db.Column(db.String(256), nullable=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'default': self.default,
            'min': self.min,
            'max': self.max,
            'states': json.loads(self.states),
            'type': self.type,
            'offset': self.offset,
            'endian': self.endian,
            'description': self.description
        }

    @staticmethod
    def create_from_config(command_id, config):
        command_parameter = CommandParameter(
            command_id=command_id, 
            name=config["name"],
            endian=config["endian"], 
            description=config["description"],
            default=config["default"],
            min=config["min"],
            max=config["max"],
            states=json.dumps(config["states"]),
            type=config["type"],
            offset=config["offset"],
        )

        db.session.add(command_parameter)
        db.session.commit()

        return command_parameter
    
class InterceptedCommand(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    base_command_id = db.Column(db.Integer, db.ForeignKey('command.id'), nullable=False)
    parameters = db.relationship('InterceptedCommandParameter', order_by="InterceptedCommandParameter.id.asc()", backref='intercepted_command')
    command = db.relationship('Command')

    def to_dict(self):
        return {
            'id': self.id,
            'command': self.command.to_dict(),
            'parameters': [parameter.to_dict() for parameter in self.parameters]
        }

class InterceptedCommandParameter(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    base_parameter_id = db.Column(db.Integer, db.ForeignKey('command_parameter.id'), nullable=False)
    intercepted_command_id = db.Column(db.Integer, db.ForeignKey('intercepted_command.id'), nullable=False)
    value = db.Column(db.String(256), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'base_parameter_id': self.base_parameter_id,
            'intercepted_command_id': self.intercepted_command_id,
            'value': self.value
        }

#intercepted_command = db.relationship('InterceptedCommand', back_populates='parameters')
