require 'spec_helper'
require './server'

RSpec.configure do |c|
  c.include Helper
end

RSpec.describe Server do
  describe '.content type' do
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
  end
end