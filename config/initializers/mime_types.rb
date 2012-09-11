# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
Mime::Type.register "font/truetype", :ttf
Mime::Type.register "font/opentype", :otf
Mime::Type.register "application/vnd.ms-fontobject", :eot
Mime::Type.register "application/x-font-woff", :woff

Mime::Type.register_alias "text/html", :full
Mime::Type.register_alias "text/html", :mobile
Mime::Type.register_alias "text/javascript", :jsmobile
