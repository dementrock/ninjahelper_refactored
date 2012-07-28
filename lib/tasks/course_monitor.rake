require 'rubygems'
require 'rufus/scheduler'
require 'eventmachine'

task :course_monitor => :environment do
  EM.run do
    scheduler = Rufus::Scheduler::EmScheduler.start_new
    scheduler.every "5m", blocking: true do
      Course.all.to_a.find_all(&:has_watchers?).each do |course|
        Rails.logger.info "updating course info for #{course.ccn}"
        course.update_enrollment_info
        if course.enrollment_diff.length > 0
          course.watchers.each do |watcher|
            EnrollmentChangeMailer.enrollment_change_email(watcher, course).deliver
          end
        end
      end
    end
  end
end
