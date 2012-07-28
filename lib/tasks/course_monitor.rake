require 'rubygems'
require 'rufus/scheduler'
require 'eventmachine'

task :course_monitor => :environment do
  EM.run do
    scheduler = Rufus::Scheduler::EmScheduler.start_new
    scheduler.every "5m", blocking: true do
      Course.all.to_a.find_all(&:has_watchers?).each do |course|
        Rails.logger.info "updating course info for #{course.ccn}"
        messages = course.update_enrollment_info
        if messages.length > 0
          Rails.logger.info "sending mail to #{course.watchers.map(&:email)}"
          course.watchers.each do |watcher|
            NinjahelperMailer.enrollment_change_email(watcher, course, messages).deliver
          end
        end
      end
    end
  end
end
