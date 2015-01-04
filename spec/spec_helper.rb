require 'net/http'
require 'capybara/rspec'

module Helper
  # Makes a request to path on local server. Has 3 attempts to issue a
  # successful request. This is done because making requests too quickly
  # results in Errno::ECONNREFUSED
  def make_request(path)
    tries = 3
    Net::HTTP.get_response(URI("http://localhost:2835#{path}"))
  rescue Errno::ECONNREFUSED
    retry unless (tries -= 1).zero?
  end
end

RSpec.configure do |config|
  config.include Helper
end

Capybara.default_driver = :selenium
Capybara.app_host = 'http://localhost:2835'
Capybara.run_server = false
