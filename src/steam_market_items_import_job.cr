require "sidekiq/cli"

class SteamMarketItemsImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import_items"
    job.retry = true
  end

  def perform(app_id : String, response : Array(String), status : String)
    raise "You shall not pass!"
  end
end
