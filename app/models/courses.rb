require 'berkeley_courses.rb'

class Courses < ActiveRecord::Base
  include BerkeleyCourses
  attr_protected

end
