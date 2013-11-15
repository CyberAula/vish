ProfilesController.class_eval do
	private
	
	def profile_params
    	params.
      		require(:profile).
      		permit(:name, :organization, :birthday, :city, :country, :description,
             :phone, :mobile, :fax, :email, :address, :website,
             :experience,
             :tag_list, :occupation)
 	end
end