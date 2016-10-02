require "./steam_price_fetcher/*"
require "./price_worker"
require "sidekiq/cli"

module SteamPriceFetcher
end

cli = Sidekiq::CLI.new
server = cli.configure do |config|
end

cli.run(server)
