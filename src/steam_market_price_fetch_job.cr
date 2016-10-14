require "http"
require "sidekiq/cli"
require "./http_client"
require "./services/request_retryer"
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

    client = HTTPClient.proxied_client("steamcommunity.com")

    item_names.each do |item|
      results[item] = RequestRetryer.new.with_retry do
        client.get(URL.gsub("%{app_id}", app_id).gsub("%{name}", URI.escape(item, true)))
      end
    end

    results.each do |item_name, response|
      SteamMarketPriceImportJob.async.perform(app_id, item_name, response.body.lines.first, response.status_code.to_s)
    end
  end
end
