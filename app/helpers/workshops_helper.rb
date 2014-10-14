# encoding: utf-8

module WorkshopsHelper
  def edit_details_path(workshop)
    return workshop_path(workshop) + "/edit_details"
  end
end
