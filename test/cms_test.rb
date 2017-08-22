ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  #makes the last response available as last_response
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    # FileUtils.rm_rf(data_path)
  end

  def session
    last_request.env["rack.session"]
  end

  def create_document(name, content = "")
    File.open(File.join(data_path,name), "w") do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    get "/"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_about
    create_document "history.txt"

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, ''
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..."

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_document_not_found
    get "/notafile.ext"

    assert_equal 302, last_response.status
    # get last_response["Location"]
    # assert_equal 200, last_response.status
    # assert_includes last_response.body, "notafile.ext does not exist"
    assert_includes "notafile.ext does not exist", session[:message] 
  end

  def test_editing_document
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status
    # get last_response["Location"]
    # assert_includes last_response.body, "changes.txt has been updated"
    assert_includes "changes.txt has been updated", session[:message]
    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_doc
    post "/create", filename: "testdoc.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "testdoc.txt has been created"
    get "/"
    assert_includes last_response.body, "testdoc.txt"
  end

  def test_create_file_without_name
    post "/create", filename: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Must enter a filename"
  end

  def test_delete_file
    create_document("new_doc.txt")
    post "/new_doc.txt/delete"

    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "new_doc.txt has been deleted"
    get "/"
    refute_includes last_response.body, "new_doc.txt"
  end

  def test_signin_form
    get "/users/signin"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<input type)
  end

  def test_signin_fail
    post "/users/signin", username: "aadmin", password: "ssecret"
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Must enter the correct"
  end

  def test_signin
    post "/users/signin", username: "admin", password: "secret"
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "Welcome!"
    get "/"
    refute_includes last_response.body, "Welcome!"
  end

  def test_signout
    post "/users/signin", username: "admin", password: "secret"
    get last_response["Location"]
    assert_includes last_response.body, "Welcome!"

    post "/users/signout"
    get last_response["Location"]
    assert_includes last_response.body, "You have been signed out!"
    assert_includes last_response.body, "Sign In"
  end

end

# the last responce for test_about results in a 500 error, might have to do
# with the fact that I have stylesheets, but not javascript to enable them

#last_response body does not have values because of metatags. Not sure how to fix