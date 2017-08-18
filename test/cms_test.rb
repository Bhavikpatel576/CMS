ENV["RACK_TEST"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "about.txt"
    assert_includes last_response.body, "changes.txt"
    assert_includes last_response.body, "history.txt"
  end

  def test_about
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal true, last_response.body.include?("Lorem ipsum")
  end

  def test_incorrect_index
    get "/blah"

    assert_equal 302, last_response.status
    
    get last_response["Location"]

    assert_equal 200, last_response.status
    assert_includes last_response.body, "An incorrect page was loaded"
    assert_includes "poop", last_response.body
  end

  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 100, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-type"]
    assert_includes last_response.body, "<h1>Test the header</h1>"
  end
end

# the last responce for test_about results in a 500 error, might have to do
# with the fact that I have stylesheets, but not javascript to enable them

#last_response body does not have values because of metatags. Not sure how to fix