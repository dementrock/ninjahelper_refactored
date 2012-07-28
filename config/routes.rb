Ninjahelper::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  devise_scope :user do
    root :to => "devise/sessions#new"
  end
  devise_for :users
  resources :users, :only => [:show, :index] do
    resources :watched_courses, :controller => "user_watched_courses", :only => [:create, :destroy, :index]
    #match "watched_courses" => "watch_courses#create", via: :post, as: :watched_courses
    #match "watched_courses/(:ccn)" => "watch_courses#delete", via: :delete, as: :watched_course
  end
  #match "check_course" => "watch_courses#check", via: :post, as: :check_course
end
