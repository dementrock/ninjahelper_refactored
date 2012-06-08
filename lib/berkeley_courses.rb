module BerkeleyCourses
  def time_conflict?(course1, course2)
    time1 = course1.time.time_interval
    time2 = course2.time.time_interval
  end
end
