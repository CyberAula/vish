module SubjectsHelper

  NAME_MAX_LENGTH = 30

  # Return a link to this subject with the name
  def link_name(subject, options = {})
    return "<a href=\"/users/#{subject.slug}\">#{subject.name}</a>" if request.format == :mobile
     "<script type='text/javascript'>
       #{h modal_for(subject)}
     </script>
     <a data-toggle=\"modal\" href=\"#user-modal-#{subject.slug}\" class=\"user-modal-button-#{subject.slug} modal-no-trigger\">#{subject.name}</a>"
  end

  # Return the truncated name
  def truncate_name(name, options={})
    options = {:length => NAME_MAX_LENGTH, :separator => ' '}.merge options
    h truncate(name,options)
  end
end
