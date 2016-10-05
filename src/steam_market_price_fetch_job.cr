require "http"
require "sidekiq/cli"
require "redis"
require "./steam_market_price_import_job"

class SteamMarketPriceFetchJob
  URL =
    "http://steamcommunity.com/market/priceoverview/?country=US&currency=1&appid=%{app_id}&market_hash_name=%{name}"

  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch"
    job.retry = true
  end

  def perform(app_id : String, item_names : Array(String))
    results = {} of String => HTTP::Client::Response


    item_names.each_with_index do |item, index|
      try = 0
      while try < 20
        if get_request_count >= 20
          sleep(61 - Time.now.second)
        end
        # puts "Item[#{index}] #{Time.now} '#{item}' request_count: #{get_request_count}"
        response = HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{name}", URI.escape(item, true)))
        increment_request_count
        sleep 1
        # puts "Code: #{response.status_code}"
        # puts response.body.lines.join(" ")
        if response.status_code == 429
          try += 1
          # puts "What a pity, we need some sleep to get item #{item}... Zzz..."
          set_request_count_to_maximum
        else
          results[item] = response
          break
        end
      end
    end

    results.each do |item_name, response|
      SteamMarketPriceImportJob.async.perform(app_id, item_name, response.body.lines.first, response.status_code.to_s)
    end
  end

  def get_request_count : Int32
    (REDIS.get(request_count_key) || "0").to_i
  end

  def increment_request_count
    REDIS.incr(request_count_key)
  end

  def set_request_count_to_maximum
    REDIS.set(request_count_key, 20)
  end

  def request_count_key
    @fetcher_id ||= SteamPriceFetcher::FetcherId.get_id
    request_time = Time.now.to_s("%Y%m%d%H%M")
    "fetcher:#{@fetcher_id}:#{request_time}"
  end
end
