require "sidekiq/cli"

class SteamMarketPriceImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import"
    job.retry = true
  end

  def perform(app_id : String, item_name : String, response : String, status : String)
    raise "You shall not pass!"
  end
end
