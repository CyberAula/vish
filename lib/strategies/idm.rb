require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Idm < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "idm"

      unless Vish::Application.config.APP_CONFIG["OAUTH2"].blank?
        # This is where you pass the options you would pass when
        # initializing your consumer from the OAuth gem.
        option :client_options, {
          :site => Vish::Application.config.APP_CONFIG["OAUTH2"]["site"],
          :authorize_url => Vish::Application.config.APP_CONFIG["OAUTH2"]["authorize_path"],
          :token_url     => Vish::Application.config.APP_CONFIG["OAUTH2"]["token_url"]
        }
      end

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ raw_info['id'] }

      info do
        {
          :name => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        #/users?access_token=MYTOKEN
        @raw_info ||= access_token.get('/user').parsed
      end

      def callback_url
         full_host + script_name + callback_path
      end
    end
  end
end
