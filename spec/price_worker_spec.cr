require "./spec_helper"
require "../src/price_worker"

describe PriceWorker do
  it 'send request to steam for each item' do
    worker = PriceWorker.new

  end
end
