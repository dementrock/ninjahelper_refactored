require 'nokogiri'
require 'open-uri'

class String
  def remove_non_ascii(replacement="") 
    self.gsub(/[\u0080-\u00ff]/, replacement)
  end 
end

namespace :schedule do

  CLASSIFS = {
      :L => "lower division",
      :U => "upper division",
      :G => "graduate",
      :P => "professional",
      :M => "special study for master's exam",
      :D => "special study for doctoral qualifying exam",
      :O => "other",
  }

  def separate_time_location(str_time_location)
    time = ""
    location = ""
    if str_time_location =~ /,/
      time, location = str_time_location.split(/,/)
    elsif str_time_location =~ /UNSCHED(.*)/
      time, location = "UNSCHED", $1
    elsif str_time_location =~ /(.*)NO FACILITY/
      time, location = $1, "NO FACILITY"
    elsif str_time_location =~ /TBA|CANCELLED/
      time = location = str_time_location
    else
      time = location = str_time_location
      logger.error "unrecognized location string: #{str_time_location}"
    end
    return time.strip, location.strip
  end

  def get_info_from_course_table(course_table)
    info_list = course_table.xpath(".//tr")
                            .map(&X.text.gsub(/&nbsp;?/, " ").squish)
                            .reject(&:blank?)
                            .map(&X.remove_non_ascii.slice(/^.+?:(.*)/, 1)) # There is a strange character in front of each line, which needs to be removed
    info_name_list = [:course_full_name,
                      :course_title,
                      :location,
                      :instructor,
                      :status,
                      :course_control_number,
                      :units,
                      :final_exam_group,
                      :restrictions,
                      :note,
                      :enrollment,
                     ]
    info = Hash[info_name_list.zip(info_list)]
    info[:time], info[:location] = separate_time_location info[:location]
    if info[:enrollment] =~ /Limit:(\d+) Enrolled:(\d+) Waitlist:(\d+) Avail Seats:(\d+)/
      info[:enrollment_limit], info[:enrolled], info[:waitlist], info[:avail_seats] = $1, $2, $3, $4
    end
    # This is based on the assumption that there's no digits in department names, and course number must contain at least one number
    course_name_segments = info[:course_full_name].split
    department_name = course_name_segments.take_while(&X =~ /^\D*$/)
    course_number, course_dependency_type, course_section_number, course_type = course_name_segments[department_name.length..-1]
    info[:department_name] = department_name.join ' '
    info[:course_number] = course_number
    info[:course_dependency_type] = course_dependency_type
    info[:course_section_number] = course_section_number
    info[:course_type] = course_type
    info
  end

  def process_schedule_page(schedule_page)
    schedule_page.xpath("//body/table")[1..-2].each do |course_table|
      info = get_info_from_course_table course_table
      if not info[:course_control_number].nil? and info[:course_control_number].length == 5
        course = Courses.find_or_create_by_course_control_number(info[:course_control_number])
        course.update_attributes info
      end
    end
  end

  task :test => :environment do
    process_schedule_page(Nokogiri::HTML(open("http://localhost/~dementrock/schedule.html")))
  end

  task :update_courses => :environment do
    term = "FL"
    raw_schedule_url = "http://osoc.berkeley.edu/OSOC/osoc?p_term=%{term}&p_classif=%{classif}&p_start_row=%{start_row}"

    CLASSIFS.each_key do |classif|
      puts "fetching classification #{classif} with start_row #{1}"
      first_page_url = raw_schedule_url % {:term => term, :classif => classif, :start_row => 1}
      first_page = Nokogiri::HTML(open(first_page_url))
      total_count = first_page.xpath("//body/table").first.to_s.match(/Displaying \d+\-\d+ of (\d+)/)[1].to_i
      process_schedule_page(first_page)
      (101..total_count).step(100).each do |start_row|
        puts "fetching classification #{classif} with start_row #{start_row}"
        page_url = raw_schedule_url % {:term => term, :classif => classif, :start_row => start_row}
        page = Nokogiri::HTML(open(page_url))
        process_schedule_page(page)
      end
    end
  end
end
