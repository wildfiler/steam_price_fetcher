require "sidekiq/cli"

class SteamMarketItemsImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import_items"
    job.retry = true
  end

  def perform(app_id : String, item_names : Array(String))
    raise "You shall not pass!"
  end
end
