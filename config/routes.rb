GooglePlayCrawler::Application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  resource :accounts, :only => [:new, :create]
  resources :libs, :only => :index

  get '/'                      => 'apps#index'
  get 'updated_apps'           => 'apps#updated_apps_index'
  get 'search'                 => redirect('/')
  get 'sources'                => 'sources#search'
  get 'apps/:app_id'           => 'apps#show',    :app_id => /[^\/]+/
  get 'apps/:app_id/:filename' => 'sources#show', :app_id => /[^\/]+/, :filename => /.+/

  get '/matches' => 'matches#index'
  post '/matches/:app_id' => 'matches#match', :app_id => /[^\/]+/
end
