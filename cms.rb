require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"
require "redcarpet"


configure do 
    enable :sessions
    set :session_secret, 'secret'
    # set :erb, :escape_html => true
end

def valid_user?(username, password)
	username == 'admin' && password == 'secret'
end

def error_for_index(name)
	#iterate through the file to see if value persists
	session[:indices].include?(name)
end

def data_path
	if ENV["RACK_ENV"] == "test"
		File.expand_path("../test/data", __FILE__)
	else
		File.expand_path("../data", __FILE__)
	end
end

def render_markdown(text)
	markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
	markdown.render(text)
end

def load_file_content(path)
	content = File.read(path)
	case File.extname(path)
	when ".txt"
		headers["Content-Type"] = "text/plain"
		content
	when ".md"
		erb render_markdown(content)
	end
end

def file_ext_validation(name)
	/\.(txt)/.match(name)
end

get "/" do
	pattern = File.join(data_path, "*")
	@data_files = Dir.glob(pattern).map {|file| File.basename(file)}
  erb :home, layout: :layout
end

get "/new" do
  erb :new
end

get "/:file" do
	file_name = params[:file].to_s
	file_path = File.join(data_path, file_name)
	if File.exist?(file_path)
		@file_data = load_file_content(file_path)
	else
		session[:message] = "#{file_name} does not exist"
		redirect "/"
	end
end

get "/:file/edit" do 
	@file_name = params[:file].to_s
	file_path = File.join(data_path, @file_name)

	if File.exist?(file_path)
		@file_data = File.read(file_path)
		erb :edit, layout: :layout
	else
		session[:error] = "An incorrect page was loaded"
		# redirect "/"
	end
end

post "/create" do
	filename = params[:filename]
	if file_ext_validation(filename)
		file_path = File.join(data_path, filename)
		File.new(file_path, "w+")
		session[:message] = "#{filename} has been created"
		redirect "/"
	else
		session[:message] = "Must enter a filename with a proper extension"
		status 422
		erb :new
	end
end

post "/:file" do
		@file_name = params[:file].to_s
		file_path = File.join(data_path, @file_name)
		File.write(file_path, params[:content])
		session[:message] = "#{@file_name} has been updated"
		redirect "/"
end

post "/:file/delete" do 
	@file_name = params[:file].to_s
	file_path = File.join(data_path, @file_name)
	File.delete(file_path)
	session[:message] = "#{@file_name} has been deleted"
	redirect "/"
end

get "/users/signin" do
	erb :signin
end

post "/users/signin" do
	if valid_user?(params[:username], params[:password])
		session[:username] = params[:username]
		session[:message] = "Welcome!"
		redirect "/"
	else
		session[:message] = "Must enter the correct username and password"
		status 422
		erb :signin
	end
end

post "/users/signout" do
		session.delete(:session_id)
		session.delete(:username)
		session[:message] = "You have been signed out!"
		redirect "/"
end


