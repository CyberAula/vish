# Ignore RMagick vs. ImageMagick versions
RMAGICK_BYPASS_VERSION_TEST = true

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Vish::Application.initialize!
