require 'bundler'
Bundler.require

require 'csv'


DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/main.db')
require './models.rb'


use Rack::Session::Cookie, :key => 'rack.session',
    :expire_after => 2592000,
    :secret => SecureRandom.hex(64)

use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],

           {
               :name => 'google',
               :prompt => 'select_account',
               :scopes => 'plus.login',
               :image_aspect_ratio => 'square',
               :image_size => 50
           }
end


get '/' do
  if authenticated?
    erb :home
  else
    redirect '/auth/google'
  end
end

get '/logout' do
  session.clear
  redirect '/auth/logout'
end

['get', 'post'].each do |method|
  send(method, '/auth/:provider/callback') do
    uid = request.env['omniauth.auth'].uid
    info = request.env['omniauth.auth'].info.to_hash

    unless info['email'] =~ /[a-zA-Z0-9]+\@students\.westport\.k12\.ct\.us/
      halt 401, 'Unauthorized: Email must be from @students.westport.k12.ct.us'
    end

    unless user = User.first(:uid => uid)

      user = User.new
      user.uid = uid

      user.name = info['name']
      user.image = info['image']

    end

    user.last_login = Time.now.to_i
    user.token = SecureRandom.hex(20)
    user.save

    session[:user_token] = user.token
    redirect '/'
  end
end

get '/about' do
  session.clear
  redirect 'https://www.google.com'
end
get '/auth/failure' do
  session.clear
  redirect '/home'
end

get '/auth/logout' do
  session.clear

  redirect '/home'
end

helpers do
  def current_user
    if authenticated?
      User.first(:token => session[:user_token])
    else
      halt(401, 'Unauthenticated')
    end
  end

  def authenticated?
    session[:user_token] && User.first(:token => session[:user_token])
  end
end

get '/classmates' do
  if authenticated?
  @user = User.first(:token => session[:user_token])
  @courses = @user.courses

  erb :classmates
  else
    redirect '/auth/google'
    end
end

get '/generate' do
  if authenticated?
    redirect '/classmates'
  else
    redirect '/auth/google'
  end
  #erb :classmates
end

post '/generate' do
  @user = User.first(:token => session[:user_token])
  session[:user] = @user

  full_string = params[:pasted]

  split = full_string.split("\n")

  split.each do |course|
    course_array = course.split("\t")

    first =  course_array[0]
    if course_array.length == 9 && !(c = Course.first(:course_id => course_array[0])) && first != "Course"
      #how to see if it includes 'Course'
      c = Course.new
      c.course_id = course_array[0]
      c.title = course_array[1]
      c.period = course_array[2]
      c.teacher = course_array[3]
      c.room = course_array[4]
      c.days = course_array[5]
      c.quarters = course_array[6]
      c.save

      c.add_user(@user)
    end
  end

  @courses = @user.courses

  # change erb to redirect
  redirect '/classmates'

end