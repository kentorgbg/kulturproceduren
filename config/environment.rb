# Load the rails application
require File.expand_path('../application', __FILE__)

# Creates an application config hash on a global level using settings
# in the given YAML file. Initialize this as early as possible.
APP_CONFIG = {}

app_config_yml = YAML.load_file(Rails.root.join('config', 'app_config.yml'))[Rails.env]
APP_CONFIG.merge!(app_config_yml)
app_config_local = YAML.load_file(Rails.root.join('config', 'app_config.local.yml'))[Rails.env]
APP_CONFIG.merge!(app_config_local)
app_config_confidential = YAML.load_file(Rails.root.join('config', 'app_config.confidential.yml'))[Rails.env]
APP_CONFIG.merge!(app_config_confidential)

# Initialize the rails application
Kulturproceduren::Application.initialize!
