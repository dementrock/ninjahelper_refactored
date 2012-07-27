Ninjahelper::Application.routes.draw do
  authenticated :user do
    root :to => 'home#index'
  end
  devise_scope :user do
    root :to => "devise/sessions#new"
  end
  devise_for :users
  resources :users, :only => [:show, :index]
  match "watched_courses" => "watch_courses#create", via: :post, as: :watch_course
  match "watched_courses/(:ccn)" => "watch_courses#delete", via: :delete, as: :unwatch_course
end
