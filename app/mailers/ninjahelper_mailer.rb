class NinjahelperMailer < ActionMailer::Base
  default :from => "ninjahelper.notifications@gmail.com"

  def enrollment_change_email(user, course, messages)
    @user = user
    @course = course
    @messages = messages
    
    Rails.logger.info "Send message to #{user.email} with message #{@messages}\n course info: #{course.as_document}"

    @messages.each do |message|
      if message =~ /from to/i
        Rails.logger.info "Empty from info: #{@messages}"
        return
      end
    end
      
    mail :to => user.email, :subject => "Status change of course #{course.name} with CCN #{course.ccn}"
  end

end
