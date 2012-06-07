class CreateCourses < ActiveRecord::Migration
	def change
		create_table :courses do |t|
			t.string :course_full_name
			t.string :course_title
			t.string :location
			t.string :time
			t.string :instructor
			t.string :status
			t.string :course_control_number
			t.string :units
			t.string :final_exam_group
			t.string :restrictions
			t.string :note
			t.string :enrollment
			t.string :department_name
			t.string :course_number
			t.string :course_dependency_type
			t.string :course_section_number
			t.string :course_type
		end
	end
end
