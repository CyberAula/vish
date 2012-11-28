AvatarsForRails.setup do |config|
  config.avatarable_model = :actor
  config.current_avatarable_object = :current_actor
  config.avatarable_filters = [:authenticate_user!]
  config.avatarable_styles = {
    :representation => "16x16>",                                 
    :actor => '25x25>',                                        
    :contact => "50x50>",                                      
    :profile => '119x119'
  }
end

