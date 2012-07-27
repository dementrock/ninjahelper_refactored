class EnrollmentChangeMailer < ActionMailer::Base
  default :from => "njmail123@gmail.com"

  def enrollment_change_email(user, course)
    @user = user
    @course = course
    diff = @course.enrollment_diff

    @messages = []

    if diff[:is_all_full] == true
      @messages.push "This course is now full"
    else
      if diff[:is_all_full] == false
        @messages.push "The course is changed from full to (possibly) available."
      end
      if diff[:is_waitlist_used] == true
        @messages.push "This course has a waitlist now"
      elsif diff[:is_waitlist_used] == false
        @messages.push "This course has no waitlist now"
      end
      if diff.has_key? :waitlist_limit
        @messages.push "The waitlist limit has changed from #{course.prev_info[:waitlist_limit]} to #{course.waitlist_limit}"
      end
      if diff.has_key? :current_waitlist
        message = "The current waitlist has changed from #{course.prev_info[:current_waitlist]} to #{course.current_waitlist}"
        if not diff.has_key? :waitlist_limit
          message += ", with waitlist limit #{course.waitlist_limit}"
        end
        @messages.push message
      end
      if diff.has_key? :enroll_limit
        @messages.push "The enrollment limit has changed from #{course.prev_info[:enroll_limit]} to #{course.enroll_limit}"
      end
      if diff.has_key? :current_enroll
        message = "The current enrollment has changed from #{course.prev_info[:current_enroll]} to #{course.current_enroll}"
        if not diff.has_key? :enroll_limit
          message += ", with enrollment limit #{course.enroll_limit}"
        end
        @messages.push message
      end
    end

    puts @messages
      
    mail :to => user.email, :subject => "Status change of course with CCN #{course.ccn}"
  end

end
