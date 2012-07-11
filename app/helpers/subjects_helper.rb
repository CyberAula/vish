module SubjectsHelper

  NAME_MAX_LENGTH = 30

  # Return a link to this subject with the name
  def link_name(subject, options = {})
    "<a data-toggle=\"modal\" href=\"#user-modal-#{subject.slug}\" class=\"user-modal-button-#{subject.slug}\">#{subject.name}</a>
     <script type='text/javascript'>
       $(\".user-modal-button-#{subject.slug}\").on(\"click\", function(){
         #{h modal_for(subject)}
       });
     </script>"
  end

  # Return the truncated name
  def truncate_name(name, options={})
    options = {:length => NAME_MAX_LENGTH, :separator => ' '}.merge options
    h truncate(name,options)
  end
end
