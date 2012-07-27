task :update_monitored_courses => :environment do
  Course.watched.each do |course|
    course.update
    if course.diff

    end
  end
end
