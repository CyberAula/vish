class ServiceRequest::PrivateStudentGroup < ServiceRequest
  def afterAccept
    s = ServicePermission.new
    s.owner_id = self.owner_id
    s.key = "PrivateStudentGroups"
    s.save
  end
end