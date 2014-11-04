# encoding: utf-8

module WorkshopsHelper
  def edit_details_path(workshop)
    return workshop_path(workshop) + "/edit_details"
  end

  def add_resource_to_wa_resources_gallery_path(wa_resources_gallery)
  	return wa_resources_gallery_path(wa_resources_gallery) + "/add_resource"
  end
end
