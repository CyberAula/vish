require 'spec_helper'

describe PasswordsController, controllers: true do

=begin
	 3) PasswordsController update
     Failure/Error: put :update
     AbstractController::ActionNotFound:
       Could not find devise mapping for path "/users/password".
       This may happen for two reasons:
       
       1) You forgot to wrap your route inside the scope block. For example:
       
         devise_scope :user do
           get "/some/route" => "some_devise_controller"
         end
       
       2) You are testing a Devise controller bypassing the router.
          If so, you can explicitly tell Devise which mapping to use:
       
          @request.env["devise.mapping"] = Devise.mappings[:user]
=end

end
