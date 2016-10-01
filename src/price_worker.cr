require "http"
require "sidekiq/cli"
require "redis"
require "./export_worker"

REDIS = Redis.new

class PriceWorker
  URL =
    "http://steamcommunity.com/market/priceoverview/?country=US&currency=1&appid=%{app_id}&market_hash_name=%{name}"

  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import"
    job.retry = true
  end

  def perform(app_id : String, item_names : Array(String))
    results = {} of String => HTTP::Client::Response

    item_names.each do |item|
      try = 0
      while try < 20
        response = HTTP::Client.get(URL.gsub("%{app_id}", app_id).gsub("%{name}", URI.escape(item, true)))
        puts response.body.lines
        if response.status_code == 429
          try += 1
          puts "What a pity, we need some sleep to get item #{item}... Zzz..."

          sleep 5
        else
          results[item] = response
          break
        end
      end
    end

    results.each do |item_name, response|
      ExportWorker.async.perform(app_id, item_name, response.body.lines.first, response.status_code.to_s)
    end
  end
end
