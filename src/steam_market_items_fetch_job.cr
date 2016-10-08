require "http"
require "sidekiq/cli"
require "redis"
require "xml"
require "./services/steam_request_limiter"
require "./steam_market_items_import_job"

class SteamMarketItemsFetchJob
  URL =
    "http://steamcommunity.com/market/search/render/?search_descriptions=0&sort_column=name&sort_dir=asc&appid=%{app_id}&count=100&start=%{query_start}"

  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch_items"
    job.retry = true
  end

  def perform(app_id : String, query_start : String)
    response = SteamRequestLimiter.new.limit do
      HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{query_start}", query_start))
    end

    names = get_names(response)
    SteamMarketItemsImportJob.async.perform(app_id, names)
  end

  def get_names(response : HTTP::Client::Response)
    xml = XML.parse_html(JSON.parse(response.body)["results_html"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_listing_item_name']")
    nodes.map{|node| node.content.to_s}
  end
end
