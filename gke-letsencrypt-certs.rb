#!/usr/bin/env ruby

require "httparty"
require "json"

def certificates
  response = HTTParty.get("http://localhost:8001/api/v1/services")

  json = JSON.parse(response.body)

  json["items"].each_with_object(certificates) do |item, collection|
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

puts [{"targets" => certificates.flatten}].to_json
