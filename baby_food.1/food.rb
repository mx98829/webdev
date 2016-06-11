require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "date"
require "yaml"
require "bcrypt"
require "pry"
configure do 
  enable :sessions
  set :session_secret, 'secret' 
end

before do
  @week =  {1 => "Monday", 
            2 => "Tuesday",
            3 => "Wednesday",
            4 => "Thursday",
            5 => "Friday",
            6 => "Saturday",
            0 => "Sunday"}
            
  session[:id] ||=[]
  session[:food] ||= {}
  @users = YAML.load_file("users.yaml")
end

helpers do
  
  def get_monday_date(id)
    date = Date.today
    date + (1-date.wday) + (7 * id)
  end
  
  def today_id
    date = Date.today
    ((date + (1-date.wday) - get_monday_date(0)) / 7).to_i
  end
  
  def sign_in?
    session.key?(:user)
  end
  
  def ensure_sign_in
    unless sign_in?
      session[:message] = "You must sign in to do that."
      redirect "/signin"
    end
  end
  
  def baby_name
    if session[:baby]
      session[:baby]
    else
      "your baby"
    end
  end
  
end

get "/" do
  if !session[:user]
    redirect "/signin"
  elsif !session[:food][0]
    redirect "/setup"    
  else
    redirect "/overview"
  end
end

get "/setup" do
  ensure_sign_in
  if !session[:food][0]
    erb :setup, layout: :layout
  else
    redirect "/overview"
  end
end

post "/setup" do
  session[:food][0] = {}
  session[:baby] = params[:baby_name]
  redirect "/question/0"
end

get "/signup" do
  erb :signup, layout: :layout
end

post "/signup" do
  username = params[:username]
  password = params[:password]
  
  if username.strip.empty?
     session[:message] = "Username can't be empty"
     erb :signup, layout: :layout
  elsif password.size < 6
     session[:message] = "Password must be at least 6 characters long"
     erb :signup, layout: :layout
  elsif password.scan(/\d/).empty?
     session[:message] = "password must contain at least one number"
     erb :signup, layout: :layout
  else
      @users[username] = BCrypt::Password.create(password)
      File.open("users.yaml", "w") {|file| file.write @users.to_yaml }
      session[:message] = "You have successfully signed up"
      redirect "/signin"
  end
end

get "/signin" do
  erb :signin, layout: :layout
end

post "/signin" do
  username = params[:username]
  password = params[:password]
  if @users.has_key?(username) && BCrypt::Password.new(@users[username]) == password
    session[:user] = username
    redirect "/setup"
  else
    session[:message] = "Sign in is failed"
    erb :signin, layout: :layout
  end
end

post "/signout" do
  session.delete(:user)
  session[:message] = "You have been signed out."
  redirect "/signin"
end

get "/overview" do
    
  ensure_sign_in
  
  erb :overview, layout: :layout
end

get "/question/:id" do
  
  ensure_sign_in
  @id = params[:id].to_i
 
  erb :question, layout: :layout  
end
 
post "/question/:id" do
  @id = params[:id].to_i
  if !@week.all? do |num, week|
      params[week.to_sym].empty?
    end
   
    session[:id] << @id unless session[:id].include?(@id)
    
    session[:food][@id] = {}
  
    @week.each do |num, week|
      session[:food][@id][week] = params[week.to_sym]
    end
     
    session[:message] = "The food has been saved"
  end
  
  
  
  redirect "/question/#{@id}"
end


 