require "http"
require "redis"

class SteamRequestLimiter
  def limit : HTTP::Client::Response
    try = 0
    while try < 20
      if get_request_count > 18
        sleep(61 - Time.now.second)
      end

      response = yield
      puts "Status: #{response.status_code}"
      sleep 1
      if response.status_code == 429
        try += 1
        set_request_count_to_maximum
      else
        break
      end
    end
    raise "Wtf?" unless response
    response
  end

  def get_request_count : Int32
    incr = REDIS.incr(request_count_key).to_i
    set_expire_request_count
    incr
  end

  def set_request_count_to_maximum
    REDIS.set(request_count_key, 20)
    set_expire_request_count
  end

  def set_expire_request_count
    REDIS.expire(request_count_key, 300)
  end

  def request_count_key
    @fetcher_id ||= SteamPriceFetcher::FetcherId.get_id
    request_time = Time.now.to_s("%Y%m%d%H%M")
    "fetcher:#{@fetcher_id}:#{request_time}"
  end
end