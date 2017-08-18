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

before do 
	@data_files = Dir.glob('data/*').map {|file| File.basename(file)}
	@data_files.each {|file| session[:indices] << file}
end

helpers do 
	def render_markdown(text)
		markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
		markdown.render(text)
	end
end

def error_for_index(name)
	#iterate through the file to see if value persists
	session[:indices].include?(name)
end

def data_path
	if ENV["RACK_ENV"] == "test"
		File.expand_path("../test/data", __FILE__)
	else
		FIle.expand_path("../data", __FILE__)
	end
end

get "/" do 
    erb :home, layout: :layout
end

get "/:file" do 
	file_name = params[:file].to_s
	if error_for_index(file_name)
		@file_data = File.read "data/#{file_name}"
		erb :index
	else
		session[:error] = "An incorrect page was loaded"
		redirect "/"
	end
end

get "/:file/edit" do 
	@file_name = params[:file].to_s
	if error_for_index(@file_name)
		@file_data = File.read "data/#{@file_name}"
		erb :edit
	else
		session[:error] = "An incorrect page was loaded"
		redirect "/"
	end
end

post "/:file" do
		@file_name = params[:file].to_s
		File.write("data/#{@file_name}", params[:content])
		session[:message] = "#{@file_name} has been updated"
		redirect "/"
		binding.pry
end



















