require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"
require "redcarpet"
# require "pry"

configure do 
    enable :sessions
    set :session_secret, 'secret'
    set :erb, :escape_html => true
end

#this code no longer works or can be preprocessed because of the isolated testing environment
#and the way the directory structure is set up.
# before do
	# pattern = File.join(data_path, "*")
	# @data_files = Dir.glob(pattern).map {|file| File.basename(file)}
	# @data_files.each {|file| session[:indices] << file}
# end

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
		render_markdown(content)
	end
end

get "/" do
	pattern = File.join(data_path, "*")
	@data_files = Dir.glob(pattern).map {|file| File.basename(file)}
  # erb :home, layout: :layout
  erb :home
end

get "/:file" do
	file_name = params[:file].to_s
	file_path = File.join(data_path, file_name)
	if File.exist?(file_path)
		@file_data = load_file_content(file_path)
		erb :index, layout: :layout
		# erb :index
	else
		session[:error] = "An incorrect page was loaded"
		redirect "/"
	end
end

get "/:file/edit" do 
	@file_name = params[:file].to_s
	file_path = File.join(data_path, @file_name)

	if File.exist?(file_path)
		@file_data = File.read(file_path)
		erb :edit
	else
		session[:error] = "An incorrect page was loaded"
		redirect "/"
	end
end

post "/:file" do
		@file_name = params[:file].to_s
		file_path = File.join(data_path, @file_name)
		File.write(file_path, params[:content])
		session[:message] = "#{@file_name} has been updated"
		redirect "/"
end


