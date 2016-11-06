require "http"
require "sidekiq/cli"
require "./services/steam_request_limiter"
require "./steam_market_orders_details_import_job"

class SteamMarketOrdersDetailsFetchJob
  URL =
    "https://steamcommunity.com/market/itemordershistogram?language=english&currency=1&item_nameid=%{item_nameid}&two_factor=0"
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch_orders_details"
    job.retry = true
  end

  def perform(item_nameid : String)
    escaped_url = URL.gsub("%{item_nameid}", item_nameid)

    response = SteamRequestLimiter.new.limit do
      HTTP::Client.get(escaped_url)
    end

    highest_buy_order = get_highest_buy_order(response)
    lowest_sell_order = get_lowest_sell_order(response)
    buy_order_summary = get_buy_order_summary(response)
    sell_order_summary = get_sell_order_summary(response)
    date_time = Time.now.to_s

    SteamMarketOrdersDetailsImportJob.async.perform(
      item_nameid,
      highest_buy_order,
      lowest_sell_order,
      buy_order_summary,
      sell_order_summary,
      date_time,
    )
  end

  def get_highest_buy_order(response : HTTP::Client::Response)
    result = JSON.parse(response.body)["highest_buy_order"].to_s
    result.empty? ? "0" : result
  end

  def get_lowest_sell_order(response : HTTP::Client::Response)
    result = JSON.parse(response.body)["lowest_sell_order"].to_s
    result.empty? ? "0" : result
  end

  def get_buy_order_summary(response : HTTP::Client::Response)
    xml = XML.parse_html(JSON.parse(response.body)["buy_order_summary"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_commodity_orders_header_promote']")
    nodes.empty? ? "0" : nodes[0].content.to_s
    # return "0" if nodes.empty?
    # nodes[0].content.to_s
  end

  def get_sell_order_summary(response : HTTP::Client::Response)
    xml = XML.parse_html(JSON.parse(response.body)["sell_order_summary"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_commodity_orders_header_promote']")
    nodes.empty? ? "0" : nodes[0].content.to_s
    # return "0" if nodes.empty?
    # nodes[0].content.to_s
  end
end
