require 'spec_helper'
require './server'
require 'capybara/rspec'

RSpec.configure do |c|
  c.include Helper
  Capybara.default_driver = :selenium
  Capybara.app_host = 'http://localhost:2835'
  Capybara.run_server = false
end

RSpec.describe Server do
  describe '.content_type' do
    it 'returns the correct content type for a path' do
      expect(Server.content_type('index.html')).to eq('text/html')
    end

    it 'returns the defaut content type for an unrecognized extension' do
      expect(Server.content_type('favicon.ico')).to eq('application/octet-stream')
    end
  end

  describe '.requested_file' do
    it 'returns the correct path for a root file' do
      expect(Server.requested_file('GET /file.html HTTP/1.1')).to eq('./www/file.html')
    end

    it 'returns the correct path for a nested file' do
      expect(Server.requested_file('GET /dir/file.html HTTP/1.1')).to eq('./www/dir/file.html')
    end

    it 'returns the correct path when "." is used' do
      expect(Server.requested_file('GET /dir/./file.html HTTP/1.1')).to eq('./www/dir/file.html')
    end

    it 'returns the correct path when "//" is used' do
      expect(Server.requested_file('GET /dir//file.html HTTP/1.1')).to eq('./www/dir/file.html')
    end

    it 'returns the correct path when ".." is used' do
      expect(Server.requested_file('GET /dir/../file.html HTTP/1.1')).to eq('./www/file.html')
    end

    it 'stays within WEBROOT when multiple ".." are used' do
      expect(Server.requested_file('GET /../../file.html HTTP/1.1')).to eq('./www/file.html')
    end
  end

  describe '#serve' do
    before do
      @server = Server.new
      @server.serve
    end

    after do
      @server.stop
    end

    it 'does the actual serving from a child process' do
      expect(@server.instance_variable_get(:@pid)).not_to eq(Process.pid)
    end

    it 'sets @pid' do
      expect(@server.instance_variable_get(:@pid)).not_to be_nil
    end

    it 'serves the correct file' do
      response = make_request('/test/page.html')
      expect(response.body).to eq("page.html\n")
    end

    it 'serves index.html if requested file is a directory' do
      response = make_request('/test')
      expect(response.body).to eq("index.html\n")
    end

    it 'serves the correct content type' do
      response = make_request('/test/page.html')
      expect(response.content_type).to eq("text/html")
    end

    it 'serves the correct content length' do
      response = make_request('/test/page.html')
      expect(response.content_length).to eq(10)
    end

    it 'sets status code 200 for a successful request' do
      response = make_request('/test/page.html')
      expect(response.code).to eq("200")
    end

    it 'sets status code 200 for a dir path which is served with index.html' do
      response = make_request('/test')
      expect(response.code).to eq("200")
    end

    it 'sets status code 404 for a file not found' do
      response = make_request('/test/not_there.html')
      expect(response.code).to eq("404")
    end
  end

  describe '.stop' do
    before do
      @server = Server.new
      @server.serve
    end

    it 'stops the server by killing the child process' do
      pid = @server.instance_variable_get(:@pid)
      @server.stop
      expect {
        Process.kill(0, pid)
      }.to raise_error(Errno::ESRCH)
    end

    it 'resets @pid' do
      @server.stop
      expect(@server.instance_variable_get(:@pid)).to be_nil
    end
  end

  feature 'serving correct pages' do
    before do
      @server = Server.new
      @server.serve
    end

    after do
      @server.stop
    end

    scenario 'serve a given path' do
      visit '/test/page.html'
      expect(page).to have_content('page.html')
    end

    scenario 'serve index.html if given path is directory' do
      visit '/test'
      expect(page).to have_content('index.html')
    end

    scenario 'show 404 for a file not found' do
      visit '/test/not_there.html'
      expect(page).to have_content('File not found')
    end
  end
end
