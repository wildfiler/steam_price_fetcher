require "http"

class RequestRetryer
  def with_retry : HTTP::Client::Response
    try = 0
    while try < 20 && [429, 503].includes?(response.status_code)
      response = yield
      puts "Status: #{response.status_code}"
    end

    raise "Wtf?" unless response
    raise "Status #{response.status_code} 20 times in a row" if [429, 503].includes? response.status_code
    response
  end
end
