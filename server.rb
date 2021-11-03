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

  if verb == 'GET' && path == '/'
    view      = File.read('./index.html').gsub("\n", " ")
    messages  = File.readlines('./messages.txt')
    tag_regex = /<for-each messages>(.*?)<\/for-each>/

    tag_substitution = ''

    if tag_match = view.match(tag_regex)
      messages.each_with_object(tag_substitution) do |message, acc|
        timestamp, text = message.split(';')

        acc << tag_match[1].strip
          .gsub("{{timestamp}}", timestamp)
          .gsub("{{text}}", text)
      end
    end

    body     = view.gsub(tag_regex, tag_substitution)
    response = "HTTP/1.1 200\r\nContent-Type: text/html\r\n\r\n#{body}"
  elsif verb == 'POST' && path == '/'
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

