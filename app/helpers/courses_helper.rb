module CoursesHelper
  
  def course_thumb_for(course,size=nil)
    image_tag (course.avatar.url || "/assets/logos/original/excursion-00.png")
  end

end
