# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120607075030) do

  create_table "courses", :force => true do |t|
    t.string "course_full_name"
    t.string "course_title"
    t.string "location"
    t.string "time"
    t.string "instructor"
    t.string "status"
    t.string "course_control_number"
    t.string "units"
    t.string "final_exam_group"
    t.string "restrictions"
    t.string "note"
    t.string "enrollment"
    t.string "department_name"
    t.string "course_number"
    t.string "course_dependency_type"
    t.string "course_section_number"
    t.string "course_type"
    t.string "enrollment_limit"
    t.string "enrolled"
    t.string "waitlist"
    t.string "avail_seats"
  end

end
