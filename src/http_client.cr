## CLIENT
require "http/client"
require "./http_proxy"

class HTTPClient < ::HTTP::Client

  def set_proxy(proxy : HTTPProxy)
    begin
      @socket = proxy.open(connection_options: proxy_connection_options)
    rescue IO::Error
      @socket = nil
    end
  end

  def proxy_connection_options
    opts                    =   {} of Symbol => Float64 | Nil

    opts[:dns_timeout]      =   @dns_timeout
    opts[:connect_timeout]  =   @connect_timeout
    opts[:read_timeout]     =   @read_timeout

    return opts
  end

  def self.proxied_client(host : String)
    options  = {} of Symbol => String
    options[:user] = ENV["PROXY_USER"] || ""
    options[:password] = ENV["PROXY_PASSWORD"] || ""
    proxy = HTTPProxy.new(
      proxy_host: ENV["PROXY_HOST"] || "localhost",
      proxy_port: (ENV["PROXY_PORT"] || 9292).to_i,
      options: options
    )
    client = HTTPClient.new(host)
    client.set_proxy(proxy)
    client
  end
end
