class Watch
	include Mongoid::Document
	include Mongoid::Timestamps

	field :is_watching_waitlist, type: Boolean
	belongs_to :user, class_name: "User", inverse_of: :watches
	belongs_to :course, class_name: "Course", inverse_of: :watches

	def wl?
		self.is_watching_waitlist
	end

	def wl=(x)
		self.is_watching_waitlist = x
		self.save!
	end

end
