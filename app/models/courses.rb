class Courses < ActiveRecord::Base
	attr_protected
  def time_interval
    return nil if self.time =~ /CANCELLED|TBA|UNSCHED|NO FACILITY/ || self.time.blank?
    raw_day, raw_time_in_day = self.time.split
    raw_day.gsub!(/SA/, "Sa")
    day = []
    Date::DAYNAMES.each do |dayname|
      if raw_day.nil?
        break
      end
      if raw_day.starts_with?(dayname[0..1])
        day << dayname
        raw_day = raw_day[2..-1]
      elsif raw_day.starts_with?(dayname[0]) && (raw_day.length < 2 || raw_day[1].downcase != raw_day[1]) # to prevent Tuesday matched to "Th"
        day << dayname
        raw_day = raw_day[1..-1]
      end
    end
    day
  end
end
