class WatchCoursesController < ApplicationController
  before_filter :authenticate_user!

  def create
    user = current_user
    course = Course.find_or_create_by(ccn: params[:ccn])
    unless user.watched_courses.include? course
      user.watched_courses << course
    end
    redirect_to root_path
  end

  def delete
    user = current_user
    course = Course.where(ccn: params[:ccn]).first
    puts user
    puts course
    if course
      user.watched_courses.delete(course)
      user.save!
    end
    redirect_to root_path
  end
end
