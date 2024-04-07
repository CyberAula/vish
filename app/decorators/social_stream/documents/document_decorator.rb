Document.class_eval do
	validates_attachment_size :file, :in => 0.megabytes..Vish::Application.config.max_file_allowed.megabytes, :message => 'size is too big (maximum file size allowed is ' + Vish::Application.config.max_file_allowed.to_s + ' MB)'
end