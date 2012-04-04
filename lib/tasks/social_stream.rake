namespace :social_stream do
  namespace :migrations do
    desc "Copy pending migrations from social_stream components"
    task "update" do
      Rake::Task['railties:install:migrations'].reenable
      Rake::Task['mailboxer_engine:install:migrations'].invoke
      File.read(File.expand_path("../../../Gemfile", __FILE__)).
           scan(/gem.*social_stream-(\w*)/).
           flatten.
           each do |d|
             Rake::Task['railties:install:migrations'].reenable
             Rake::Task["social_stream_#{ d }_engine:install:migrations"].invoke
           end
    end
  end
end
