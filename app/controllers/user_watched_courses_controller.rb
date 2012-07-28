class UserWatchedCoursesController < ApplicationController

  before_filter :authenticate_user!

  def render_json_errors(errors)
    render json: errors, status: 403
  end

  def create
    user = current_user
    course = Course.find_or_create_by(ccn: params[:ccn])
    if course.errors.any?
      render_json_errors course.errors
      return
    end
    if not course.ccn_valid?
      render_json_errors course: ["not found"]
      return
    end
    if user.watched_courses.include? course
      render_json_errors course: ["has already been watched"]
      return
    end
    user.watched_courses << course
    user.save!
    render json: course
  end

  def destroy
    user = current_user
    puts params
    course = Course.find(params[:id])
    if course
      user.watched_courses.delete(course)
      user.save!
      respond_to do |format|
        format.json { render json: course }
        format.html { redirect_to :root }
      end
    else
      respond_to do |format|
        format.json { render_json_errors course: ["does not exist"] }
        format.html { redirect_to :root }
      end
    end
  end
end
