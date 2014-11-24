module ActivityObjectHelper
  
  def ao_metadata_path(ao)
    return ao_object_metadata_path(ao.object)
  end

  def ao_object_metadata_path(object)
    return polymorphic_path(object) + "/metadata.xml"
  end

end