require 'rubygems'
require 'rufus/scheduler'
require 'eventmachine'

task :course_monitor => :environment do
  EM.run do
    scheduler = Rufus::Scheduler::EmScheduler.start_new
    scheduler.every "5m", blocking: true do

      # Course.all.to_a.find_all(&:has_watchers?).each do |course|
      #   Rails.logger.info "updating course info for #{course.ccn}"
      #   messages = course.update_enrollment_info
      #   if messages.length > 0
      #     Rails.logger.info "sending mail to #{course.watchers.map(&:email)}"
      #     course.watchers.each do |watcher|
      #       NinjahelperMailer.enrollment_change_email(watcher, course, messages).deliver
      #     end
      #   end
      # end

      Watch.all.each do |watch|
        Rails.logger.info "fetching info for #{watch.course.name} with ccn #{watch.course.ccn}"
        old_info = watch.course.full_enrollment_info
        messages = course.update_enrollment_info
        if messages.length > 0
          if watch.wl? and messages[:current_waitlist]
            if messages[:current_waitlist] == old_info[:waitlist_limit] and \
              old_info[:current_waitlist] != old_info[:waitlist_limit] or \
              messages[:current_waitlist] != old_info[:waitlist_limit] and \
              old_info[:current_waitlist] == old_info[:waitlist_limit]
              watch.update_status(messages[:current_waitlist])
              NinjahelperMailer.enrollment_change_email(watch.user, watch.course, watch.status).deliver
            end
          else
            if messages[:current_enroll] == old_info[:enroll_limit] and \
              old_info[:current_enroll] != old_info[:enroll_limit] or \
              messages[:current_enroll] != old_info[:enroll_limit] and \
              old_info[:current_enroll] == old_info[:enroll_limit]
              watch.update_status(messages[:current_enroll])
              NinjahelperMailer.enrollment_change_email(watch.user, watch.course, watch.status).deliver
            end
          end
        end




      end
    end
  end
end
