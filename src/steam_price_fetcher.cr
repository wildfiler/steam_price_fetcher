require "./steam_price_fetcher/*"
require "./price_worker"
require "sidekiq/cli"

module SteamPriceFetcher
end

cli = Sidekiq::CLI.new
server = cli.configure do |config|
end


# PriceWorker.async.perform("570", ["Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!","Exalted Demon Eater", "Taunt: Fiendish Swag!", "Scythe of Ice"])
# cli.run(server)
output = MemoryIO.new
args = [
  "ifconfig",
  "| egrep '[[:digit:]]{3,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'",
  "| grep -v '127.0.0.1'",
  "| gsed -r 's/^.*(1[0-9]{2,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*$/\1/'"
]
Process.run("ifconfig | grep -v '127.0.0'",
            output: output, shell: true)

puts (output.to_s.match(/(1[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/m)||[""])[1].to_s

