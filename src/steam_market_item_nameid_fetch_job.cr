require "http"
require "sidekiq/cli"
require "./http_client"
require "./services/request_retryer"
require "./steam_market_item_nameid_import_job"
require "./steam_market_item_prices_history_import_job"

class SteamMarketItemNameidFetchJob
  URL =
    "http://steamcommunity.com/market/listings/%{app_id}/%{item_name}"
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch_item_nameid"
    job.retry = true
  end

  def perform(app_id : String, item_name : String, skip_nameid : Bool)
    escaped_item_name = URI.escape(item_name.gsub("/", "-"), false)
    escaped_url = URL.gsub("%{app_id}", app_id).gsub("%{item_name}", escaped_item_name)

    client = HTTPClient.proxied_client("steamcommunity.com")

    response = RequestRetryer.new.with_retry do
      client.get(escaped_url)
    end

    body = response.body.to_s

    unless skip_nameid
      nameid = extract_nameid body
      SteamMarketItemNameidImportJob.async.perform(app_id, item_name, nameid)
    end

    prices_json = extract_prices body
    SteamMarketItemPricesHistoryImportJob.async.perform(app_id, item_name, prices_json.to_json)
  end

  def extract_nameid(body : String) : String
    nameid_match = body.match(/Market_LoadOrderSpread\( (\d+) \)/m)
    raise "Item not found in Steam market" unless nameid_match
    nameid_match[1]
  end

  def extract_prices(body : String)
    price = body.match(/var line1=(\[.*?\]);/m)
    raise "Prices history not found in Steam market" unless price
    prices = Array(Tuple(String, Float32, String)).from_json(price[1])
    total_amount = prices.map do |p|
      p[2].to_i
    end.sum
    #all_time_median
    all_time_median = median(prices, total_amount)

    last_30_amount = prices.last(30*24).map{|p| p[2].to_i}.sum
    last_30_median = median(prices.last(30*24), last_30_amount)

    last_7_amount = prices.last(7*24).map{|p| p[2].to_i}.sum
    last_7_median = median(prices.last(7*24), last_7_amount)

    last_24h_amount = prices.last(24).map{|p| p[2].to_i}.sum
    last_24h_median = median(prices.last(24), last_24h_amount)

    {
      total_amount: total_amount,
      all_time_median: all_time_median,
      last_30_amount: last_30_amount,
      last_30_median: last_30_median,
      last_7_amount: last_7_amount,
      last_7_median: last_7_median,
      last_24h_amount: last_24h_amount,
      last_24h_median: last_24h_median,
      fetched_at: Time.now.to_s
    }
  end

  def median(prices, amount)
    prices.reduce([] of Float32) do |medians, price|
      price[2].to_i.times{ medians << price[1] }
      medians
    end.sort[amount/2]
  end
end
