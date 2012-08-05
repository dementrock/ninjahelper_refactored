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
    if not course.supported?
      render_json_errors course: ["is not supported currently"]
      return
    end
    if user.watched? course
      render_json_errors course: ["has already been watched"]
      return
    end
    if params[:monitor_type == '1'] and !course.is_waitlist_used
      render_json_errors course: ["The specified course does not have a waitlist."]
    end
    # if user.watched_courses.length >= 20 # TODO move this to configuration
    if user.can_watch_more_courses?
      render_json_errors user: ["can only watch up to 20 courses"]
      return
    end
    new_watch = Watch.new
    new_watch.user = user
    new_watch.course = course
    new_watch.wl= params[:monitor_type] == '1'
    new_watch.save!
    user.watches << new_watch
    course.watches << new_watch   #dont think this is necessary
    user.save!
    course.save!
    render json: course
  end

  def destroy
    user = current_user
    puts params
    watch = Watch.find(params[:id])
    if watch
      watch.delete
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
