require 'socket'

socket = TCPServer.new(8080)
puts "Listening to the port 8080..."

loop do
  client     = socket.accept
  first_line = client.gets

  puts first_line

  client.puts("HTTP/1.1 200\r\nContent-Type: text/html\r\n\r\n<h1>FIRST</h1>")
  client.close
end
