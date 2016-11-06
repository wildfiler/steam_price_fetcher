require "redis"
require "./steam_price_fetcher/*"
require "./steam_market_price_fetch_job"
require "./steam_market_items_fetch_job"
require "./steam_market_item_nameid_fetch_job"
require "./steam_market_orders_details_fetch_job"
require "sidekiq/cli"

REDIS = Redis.new

module SteamPriceFetcher
end

cli = Sidekiq::CLI.new
server = cli.configure do |config|
end

cli.run(server)
