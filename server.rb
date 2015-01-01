require 'socket'
require 'uri'

# Files will be served from this directory
WEB_ROOT = './www'

# Map extensions to their content type
CONTENT_TYPES = {
  'html' => 'text/html',
  'css' => 'text/css'
}

# Return requested file content type based on its extension
def content_type(path)
  extension = File.extname(path).split('.').last
  CONTENT_TYPES.fetch(extension, 'text/html')
end

# Return a path to a file on the server based on the Request-Line
def requested_file(request_line)
  request_uri = request_line.split(' ')[1]
  path = URI.unescape(URI(request_uri).path)

  clean = []

  # Split the path into components
  parts = path.split("/")

  parts.each do |part|
    # skip any empty or current directory (".") path components
    next if part.empty? || part == '.'
    # If the path component goes up one directory level (".."),
    # remove the last clean component.
    # Otherwise, add the component to the Array of clean components
    part == '..' ? clean.pop : clean << part
  end

  # return the web root joined to the clean path
  File.join(WEB_ROOT, *clean)
end

# Create a new server on port 2835 (1 ounce = 28.35 grams)
server = TCPServer.new('localhost', 2835)
puts 'Listening on http://localhost:2835...'

loop do
  # Trap ^C
  Signal.trap("INT") {
    puts 'Shutting down'
    exit
  } 

  socket = server.accept
  request_line = socket.gets

  STDERR.puts "* #{request_line}"

  path = requested_file(request_line)
  # Serve index.html if requested file is a directory
  path = File.join(path, 'index.html') if File.directory?(path)

  # Make sure the file exists and is not a directory
  # before attempting to open it.
  if File.exist?(path) && !File.directory?(path)
    File.open(path, "rb") do |file|
      socket.print "HTTP/1.1 200 OK\r\n" +
                   "Content-Type: #{content_type(file)}\r\n" +
                   "Content-Length: #{file.size}\r\n" +
                   "Connection: close\r\n"

      socket.print "\r\n"

      # write the contents of the file to the socket
      IO.copy_stream(file, socket)
    end
  else
    message = "File not found\n"

    # File not found, respond with a 404 Not Found error code
    socket.print "HTTP/1.1 404 Not Found\r\n" +
                 "Content-Type: text/plain\r\n" +
                 "Content-Length: #{message.size}\r\n" +
                 "Connection: close\r\n"

    socket.print "\r\n"

    socket.print message
  end

  socket.close
end
