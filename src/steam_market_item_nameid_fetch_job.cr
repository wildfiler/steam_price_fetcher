require "http"
require "sidekiq/cli"
require "./services/steam_request_limiter"
require "./steam_market_item_nameid_import_job"

class SteamMarketItemNameidFetchJob
  URL =
    "http://steamcommunity.com/market/listings/%{app_id}/%{item_name}"
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "fetch_item_nameid"
    job.retry = true
  end

  def perform(app_id : String, item_name : String)
    response = SteamRequestLimiter.new.limit do
      HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{item_name}", URI.escape(item_name, false)))
    end

    nameid_match = response.body.to_s.match(/Market_LoadOrderSpread\( (\d+) \)/m)

    raise "Item not found in Steam market" unless nameid_match

    SteamMarketItemNameidImportJob.async.perform(app_id, item_name, nameid_match[1])
  end
end
