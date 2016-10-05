require "http"
require "sidekiq/cli"
require "redis"
require "xml"
require "xml"
require "./steam_market_items_import_job"

# REDIS = Redis.new

class SteamMarketItemsFetchJob
  URL =
    "http://steamcommunity.com/market/search/render/?search_descriptions=0&sort_column=name&sort_dir=asc&appid=%{app_id}&count=100&start=%{query_start}"

  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch_items"
    job.retry = true
  end

  def perform(app_id : String, query_start : String)
    result = {} of String => HTTP::Client::Response


    try = 0
    while try < 20
      if get_request_count > 18
        sleep(61 - Time.now.second)
      end
      response = HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{query_start}", query_start))
      puts "Status: #{response.status_code}"
      sleep 1
      if response.status_code == 429
        try += 1
        set_request_count_to_maximum
      else
        result[query_start] = response
        break
      end
    end

    xml = XML.parse_html(JSON.parse(result[query_start].body)["results_html"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_listing_item_name']")
    names = nodes.map{|node| node.content.to_s}

    SteamMarketItemsImportJob.async.perform(app_id, names, result[query_start].status_code.to_s )
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
