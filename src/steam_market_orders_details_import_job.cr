require "sidekiq/cli"

class SteamMarketOrdersDetailsImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import_orders_details"
    job.retry = true
  end

  def perform(
    item_nameid : String,
    highest_buy_order : String,
    lowest_sell_order : String,
    buy_order_summary : String,
    sell_order_summary : String,
    date_time : String
  )
    raise "You shall not pass!"
  end
end
