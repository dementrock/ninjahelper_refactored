class AddEnrollmentToCourses < ActiveRecord::Migration

  def up
    add_column :courses, :enrollment_limit, :string
    add_column :courses, :enrolled, :string
    add_column :courses, :waitlist, :string
    add_column :courses, :avail_seats, :string
  end

  def down
    remove_column :courses, :enrollment_limit, :string
    remove_column :courses, :enrolled, :string
    remove_column :courses, :waitlist, :string
    remove_column :courses, :avail_seats, :string
  end

end
