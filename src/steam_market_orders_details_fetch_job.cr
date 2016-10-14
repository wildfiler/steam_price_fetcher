require "http"
require "sidekiq/cli"
require "./http_client"
require "./services/request_retryer"
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

    client = HTTPClient.proxied_client("steamcommunity.com")

    response = RequestRetryer.new.with_retry do
      client.get(escaped_url)
    end

    response_body = JSON.parse(response.body)

    steam_data = {
      highest_buy_order: get_highest_buy_order(response_body),
      lowest_sell_order: get_lowest_sell_order(response_body),
      buy_order_number: get_buy_order_summary(response_body),
      sell_order_number: get_sell_order_summary(response_body)
    }
    date_time = Time.now.to_s

    SteamMarketOrdersDetailsImportJob.async.perform(
      item_nameid,
      steam_data,
      date_time
    )
  end

  def get_highest_buy_order(response : JSON::Any)
    result = response["highest_buy_order"].to_s
    result.empty? ? "0" : result
  end

  def get_lowest_sell_order(response : JSON::Any)
    result = response["lowest_sell_order"].to_s
    result.empty? ? "0" : result
  end

  def get_buy_order_summary(response : JSON::Any)
    xml = XML.parse_html(response["buy_order_summary"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_commodity_orders_header_promote']")
    nodes.empty? ? "0" : nodes[0].content.to_s
  end

  def get_sell_order_summary(response : JSON::Any)
    xml = XML.parse_html(response["sell_order_summary"].to_s)
    nodes = xml.xpath_nodes("//span[@class='market_commodity_orders_header_promote']")
    nodes.empty? ? "0" : nodes[0].content.to_s
  end
end
