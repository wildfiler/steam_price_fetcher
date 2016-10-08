require "sidekiq/cli"

class SteamMarketItemNameidImportJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "import_item_nameid"
    job.retry = true
  end

  def perform(app_id : String, item_name : String, item_nameid : String)
    raise "You shall not pass!"
  end
end
