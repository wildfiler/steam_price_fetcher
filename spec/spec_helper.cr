require "spec2"
require "../src/steam_price_fetcher"
require "sidekiq/cli"
require "spec2-mocks"
require "webmock"

POOL = Sidekiq::Pool.new(1)

class MockContext < Sidekiq::Context
  getter pool
  getter logger
  getter output
  getter error_handlers

  def initialize
    @pool = POOL
    @output = MemoryIO.new
    @logger = ::Logger.new(@output)
    @error_handlers = [] of Sidekiq::ExceptionHandler::Base
  end
end

Sidekiq::Client.default_context = MockContext.new

# Spec2.before_each do
#   Sidekiq.redis { |c| c.flushdb }
# end

include Spec2::GlobalDSL
