from run import app, db
from models import Setting

# Create the Flask application and initialize the database
app.app_context().push()

def prepopulate_settings():
    # Define the settings to be added
    initial_settings = [
        {'name': 'configs_loaded', 'value': 'False'},
        {'name': 'satellite_ip', 'value': '10.10.10.10'},
        {'name': 'groundstation_ip', 'value': '10.10.20.10'},
        {'name': 'command_port', 'value': '5012'},
        {'name': 'telemetry_port', 'value': '5013'},
        {'name': 'interceptor_port', 'value': '5012'},
        {'name': 'cloaking_device_port', 'value': '5013'}
    ]

    # Add settings to the database
    for setting in initial_settings:
        existing_setting = Setting.query.filter_by(name=setting['name']).first()
        if existing_setting is None:
            new_setting = Setting(name=setting['name'], value=setting['value'])
            db.session.add(new_setting)
        else:
            existing_setting.value = setting['value']

    # Commit the changes to the database
    db.session.commit()
    print("Settings have been pre-populated.")

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # Create tables if they don't exist
        prepopulate_settings()