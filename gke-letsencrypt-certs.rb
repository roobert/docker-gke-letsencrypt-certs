#!/usr/bin/env ruby

require "httparty"
require "json"

response = HTTParty.get("http://localhost:8001/api/v1/services")

json = JSON.parse(response.body)

certs = []

json["items"].each_with_object(certs) do |item, collection|
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

puts [{"targets" => certs.flatten}].to_json
