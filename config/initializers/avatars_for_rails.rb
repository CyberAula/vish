AvatarsForRails.setup do |config|
  config.avatarable_model = :actor
  config.current_avatarable_object = :current_actor
  config.avatarable_filters = [:authenticate_user!]
  config.avatarable_styles = {
    :'16' => "16x16>",
    :'25' => '25x25>',
    :'50' => "50x50>",
    :'119' => '119x119'
  }
end

