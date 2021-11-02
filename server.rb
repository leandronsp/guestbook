require 'socket'

socket = TCPServer.new(8080)
puts "Listening to the port 8080..."

loop do
  client        = socket.accept
  first_line    = client.gets
  verb, path, _ = first_line.split(' ')

  puts first_line

  case [verb, path]
  in ['GET', '/']
    body     = File.read('./index.html')
    response = "HTTP/1.1 200\r\nContent-Type: text/html\r\n\r\n#{body}"
  in ['POST', '/']
    response = "HTTP/1.1 301\r\nLocation: /\r\n\r\n"
  else
    response = "HTTP/1.1 404\r\nContent-Type: text/html\r\n\r\n<p>Not Found</p>"
  end

  client.puts(response)
  client.close
end
