#!/usr/bin/env ruby

require "httparty"
require "json"

def token
  File.read("/var/run/secrets/kubernetes.io/serviceaccount/token")
end

def cacert
  "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
end

def certificates
  host = ENV["KUBERNETES_SERVICE_HOST"]
  port = ENV["KUBERNETES_PORT_443_TCP_PORT"]
  headers = { "Authorization" => "Bearer #{token}"}

  response = HTTParty.get("https://#{host}:#{port}/api/v1/services", :headers => headers, :ssl_ca_file => cacert)

  json = JSON.parse(response.body)

  json["items"].each_with_object({}) do |item, collection|
    key = %w(metadata annotations acme/certificates)

    next unless item.dig(key)

    # parse as JSON if value is array
    begin
      values = JSON.parse(item.dig(key))
    rescue
      values = item.dig(key)
    end

    collection << values
  end
end

puts [{ "targets" => certificates.flatten }].to_json
