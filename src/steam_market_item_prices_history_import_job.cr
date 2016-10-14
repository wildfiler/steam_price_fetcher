require "sidekiq/cli"

class SteamMarketItemPricesHistoryImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import_item_prices_history"
    job.retry = true
  end

  def perform(app_id : String, item_name : String, prices_json : String)
    raise "You shall not pass!"
  end
end
