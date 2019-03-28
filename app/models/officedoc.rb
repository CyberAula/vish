class Officedoc < Document  
  has_attached_file :file,
                    :url => '/:class/:id.:extension',
                    :path => ':rails_root/documents/:class/:id_partition/:filename.:extension'

  # Thumbnail file
  def thumb(size, helper)
    "#{ size.to_s }/officedoc.png"
  end

  def source_full_url(protocol)
    Embed.checkUrlProtocol(Vish::Application.config.full_domain + self.file.url, protocol)
  end

  def google_doc_url(protocol)
    "https://docs.google.com/viewer?url=" + self.source_full_url(protocol) + "&embedded=true"
  end

  def as_json(options = nil)
    {
     :id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :src => options[:helper].polymorphic_url(self, format: format),
     :type => self.class.name
    }
  end

end
