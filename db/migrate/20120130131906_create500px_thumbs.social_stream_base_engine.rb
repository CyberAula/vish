# This migration comes from social_stream_base_engine (originally 20120117135329)
RMAGICK_BYPASS_VERSION_TEST = true
require 'RMagick'

class Create500pxThumbs < ActiveRecord::Migration
  def up
    Pathname.glob(Rails.root + 'documents/pictures' + '**/original').each { |o|
      img = Magick::Image::read(o.to_s).first
      img.change_geometry('500>') { |cols, rows, img|
        img.resize!(cols, rows)
      }
      img.write(o.dirname + 'thumb1')
    }
  end

  def down
    Pathname.glob(Rails.root + 'documents/pictures' + '**/thumb1').each { |f|
      f.delete
    }
  end
end
