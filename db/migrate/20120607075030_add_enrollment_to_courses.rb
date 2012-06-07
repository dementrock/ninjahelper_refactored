class AddEnrollmentToCourses < ActiveRecord::Migration
  def change
		change_table :courses do |t| #TODO add enrollment fields
			t.string 
		end
  end
end
