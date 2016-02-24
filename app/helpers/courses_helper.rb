module CoursesHelper
  
  def course_thumb_for(course)
    image_tag (course.avatar.url || "/assets/logos/original/excursion-00.png")
  end

  def course_raw_thumbail(course)
    course.avatar.url || "/assets/logos/original/excursion-00.png"
  end

end
