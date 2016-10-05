REDIS = Redis.new

require "./steam_price_fetcher/*"
require "./steam_market_price_fetch_job"
require "./steam_market_items_fetch_job"
require "sidekiq/cli"

module SteamPriceFetcher
end

cli = Sidekiq::CLI.new
server = cli.configure do |config|
end

cli.run(server)
