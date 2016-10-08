require "http"
require "sidekiq/cli"
require "redis"
require "./services/steam_request_limiter"
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

    item_names.each do |item|
      results[item] = SteamRequestLimiter.new.limit do
        HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{name}", URI.escape(item, true)))
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
