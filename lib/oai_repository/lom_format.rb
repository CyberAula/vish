require 'oai'
module OAI::Provider::Metadata

  class LOM < Format
    def initialize
      @prefix = 'oai_lom'
      @schema = 'http://ltsc.ieee.org/xsd/LOM lomODS.xsd'
      @namespace = 'http://ltsc.ieee.org/xsd/LOM'
      @element_namespace = 'lom'
      @fields = [ :title, :description]
    end

    def header_specification
      {
        'xmlns:oai_lom' => "http://www.imsglobal.org/xsd/imsmd_v1p2",
        'xmlns:lom' => "http://ltsc.ieee.org/xsd/LOM" ,
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        'xsi:schemaLocation' => 
          %{http://www.imsglobal.org/xsd/imsmd_v1p2
             http://www.imsglobal.org/xsd/imsmd_v1p2p4.xsd}            
      }
    end

  end

end
