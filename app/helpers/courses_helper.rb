module CoursesHelper
  
  def course_thumb_for(course)
    image_tag (course.thumbnail_url)
  end

  def course_raw_thumbail(course)
    course.thumbnail_url
  end

end
