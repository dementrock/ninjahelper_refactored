class Watch
  include Mongoid::Document
  include Mongoid::Timestamps

  field :is_watching_waitlist, type: Boolean
  field :status, type: String
  belongs_to :user, class_name: "User", inverse_of: :watches
  belongs_to :course, class_name: "Course", inverse_of: :watches

  attr_accessible :status

  def wl?
    self.is_watching_waitlist
  end

  def wl=(x)
    self.is_watching_waitlist = x
  end

  def update_status(cur)
    if self.wl?
      self.status = "Waitlisted #{cur} out of #{self.course.waitlist_limit}."
      if cur != self.course.waitlist_limit
        self.status += "  Available!"
      else
        self.status += "  Currently full."
      end
    else
      self.status = "Enrolled #{cur} out of #{self.course.enroll_limit}."
      if cur != self.course.enroll_limit
        self.status += "  Available!"
      else
        self.status += "  Currently full."
      end
    end
    self.save!
  end

end
