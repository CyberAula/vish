module Ediphy
  class Engine < Rails::Engine
    initializer "widget" do
       #Initializer here
    end

     initializer "serve_assets" do |app|
       #Initializer here
       app.middleware.use ::ActionDispatch::Static, "#{root}/vendor"
    end

  end
end