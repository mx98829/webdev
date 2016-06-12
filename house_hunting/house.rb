require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  @property_list = YAML.load_file('property.yaml')
  session[:input] ||= {}
  session[:id] ||= 1
end

helpers do
  def filter_session_input
    session[:input].select { |_, value| value.values.all? { |char| !char.strip.empty? } }
  end
end

get '/' do
  erb :question, layout: :layout
end

post '/' do
  session[:input][session[:id]] = {}
  @property_list.keys.each do |p|
    session[:input][session[:id]][p] = params[p.to_sym]
  end

  @property_list.keys.each do |p|
    if params[p.to_sym].strip.empty?
      session[:message] = 'Please fill in all the information'
      redirect "/#{session[:id]}"
    end
  end

  session[:id] += 1
  session[:message] = 'The house has been added'
  redirect '/result'
end

get '/result' do
    erb :result, layout: :layout
end

post '/:id/remove' do
  id = params[:id].to_i
  session[:input].delete(id)

  session[:message] = 'The house has been removed'
  redirect '/result'
end

get '/:id' do
  @id = params[:id].to_i
  @keys = session[:input].keys
  if session[:input][@id]
    erb :edit, layout: :layout
  else
    session[:message] = 'This house is not found'
    redirect '/result'
  end
end

post '/:id' do
  @id = params[:id].to_i
  @keys = session[:input].keys

  @property_list.keys.each do |p|
    session[:input][@id][p] = params[p.to_sym]
  end

  @property_list.keys.each do |p|
    if params[p.to_sym].strip.empty?
      session[:message] = 'Please fill in all the information'
      redirect "/#{@id}"
    end
  end
  session[:message] = 'The house has been saved'
  redirect '/result'
end
