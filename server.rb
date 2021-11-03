require 'socket'
require 'cgi'

socket = TCPServer.new(8080)
puts "Listening to the port 8080..."

def process_request_and_headers(client)
  request = ''
  headers = {}

  while line = client.gets
    break if line == "\r\n"
    request += line

    if line.match(/.*?:.*?/)
      hname, hvalue = line.split(': ')
      headers[hname] = hvalue.chomp if hvalue
    end
  end

  [request, headers]
end

def process_params(client, headers)
  params = {}

  if content_length = headers['Content-Length']
    body = client.read(content_length.to_i)
    param, value = CGI.unescape(body).split('=')
    params[param] = value
  end

  params
end

loop do
  client        = socket.accept
  first_line    = client.gets
  verb, path, _ = first_line.split(' ')

  request, headers = process_request_and_headers(client)
  params = process_params(client, headers)

  puts first_line
  puts request
  puts

  case [verb, path]
  in ['GET', '/']
    view     = File.read('./index.html').gsub("\n", " ")
    rows     = File.readlines('./messages.txt')

    div_messages = '<div>'

    list_messages = rows.each_with_object(div_messages) do |row, acc|
      body = view.dup

      timestamp, text = row.split(';')
      acc << "<div><small>#{timestamp}</small><p>#{text}</p></div>"
    end

    body = view.dup
    body << "#{list_messages}</div>"
    response = "HTTP/1.1 200\r\nContent-Type: text/html\r\n\r\n#{body}"
  in ['POST', '/']
    timestamp = Time.now.strftime('%d.%B.%Y %H:%M')
    text      = params['message'].strip
    message   = "#{timestamp};#{text}\n"

    File.open('./messages.txt', 'a') { |file| file << message }

    response = "HTTP/1.1 301\r\nLocation: /\r\n\r\n"
  else
    response = "HTTP/1.1 404\r\nContent-Type: text/html\r\n\r\n<p>Not Found</p>"
  end

  client.puts(response)
  client.close
end

