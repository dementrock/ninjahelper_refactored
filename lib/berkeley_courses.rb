module BerkeleyCourses

  module ClassMethods
    def course_with_time
      self.all.reject{|x| x.time =~ /CANCEL|UNSCHE|TBA/}
    end   
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

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
      elsif raw_day.starts_with?(dayname[0]) and (raw_day.length < 2 or raw_day[1].downcase != raw_day[1]) # to prevent Tuesday matched to "Th"
        day << dayname
        raw_day = raw_day[1..-1]
      end
    end

    def format(s, length)
      "%0#{length}d" % s.to_i
    end

    raw_start_time, raw_end_time = raw_time_in_day.split(/-/).map(&X.gsub(/12/, "00"))
    raw_end_time, end_postfix = raw_end_time[0...-1], raw_end_time[-1]
    raw_start_time += "00" unless raw_start_time.length > 2
    raw_end_time  += "00" unless raw_end_time.length > 2

    raw_start_time = format(raw_start_time, 4)
    raw_end_time = format(raw_end_time, 4)

    start_hour, start_minute = raw_start_time[0..1].to_i, raw_start_time[2..3].to_i
    end_hour, end_minute = raw_end_time[0..1].to_i, raw_end_time[2..3].to_i

    if end_postfix == "P" and raw_start_time.to_i > raw_end_time.to_i
      start_postfix = "A"
    else
      start_postfix = end_postfix
    end

    start_hour += 12 if start_postfix == "P"
    end_hour += 12 if end_postfix == "P"

    start_hour = format(start_hour, 2)
    start_minute = format(start_minute, 2)
    end_hour = format(end_hour, 2)
    end_minute = format(end_minute, 2)

    return {
      :days => day,
      :start_time => "#{start_hour}:#{start_minute}",
      :end_time => "#{end_hour}:#{end_minute}",
    }

  end

  def conflict?(other_course)
    not time_conflict(other_course).zero? 
  end

  def time_conflict(other_course)
    time1 = self.time_interval
    time2 = other_course.time_interval
    if time1.nil? or time2.nil?
      return 0
    end
    common_days = time1[:days] & time2[:days]
    start1 = Time.parse(time1[:start_time]).time_of_day
    end1 = Time.parse(time1[:end_time]).time_of_day
    start2 = Time.parse(time2[:start_time]).time_of_day
    end2 = Time.parse(time2[:end_time]).time_of_day
    common_days.length * [[end1, end2].min - [start1, start2].max, 0].max
  end

end
