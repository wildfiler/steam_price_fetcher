module SteamPriceFetcher
  class FetcherId
    @@fetcher_id = ""

    def self.get_id : String
      return @@fetcher_id unless @@fetcher_id.empty?
      output = MemoryIO.new
      args = [
        "ifconfig",
        "| egrep '[[:digit:]]{3,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}'",
        "| grep -v '127.0.0.1'",
        "| gsed -r 's/^.*(1[0-9]{2,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}).*$/\1/'"
      ]
      Process.run("ifconfig | grep -v '127.0.0'",
                  output: output, shell: true)

      @@fetcher_id = (output.to_s.match(/(1[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/m)||[""])[1].to_s
    end
  end
end
