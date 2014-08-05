class Swf < Document  
              
  def thumb(size, helper)
      "#{ size.to_s }/swf.png"
  end

  def as_json(options)
    super.merge!({
      :src => options[:helper].polymorphic_url(self, format: format)
    })
  end
  
end
