# == Schema Information
#
# Table name: courses
#
#  id                     :integer         not null, primary key
#  course_full_name       :string(255)
#  course_title           :string(255)
#  location               :string(255)
#  time                   :string(255)
#  instructor             :string(255)
#  status                 :string(255)
#  course_control_number  :string(255)
#  units                  :string(255)
#  final_exam_group       :string(255)
#  restrictions           :string(255)
#  note                   :string(255)
#  enrollment             :string(255)
#  department_name        :string(255)
#  course_number          :string(255)
#  course_dependency_type :string(255)
#  course_section_number  :string(255)
#  course_type            :string(255)
#  enrollment_limit       :string(255)
#  enrolled               :string(255)
#  waitlist               :string(255)
#  avail_seats            :string(255)
#

require 'berkeley_courses.rb'

class Courses < ActiveRecord::Base
  include BerkeleyCourses
  attr_protected

end
