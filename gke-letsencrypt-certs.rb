#!/usr/bin/env ruby

require "httparty"
require "json"

response = HTTParty.get("http://localhost:8001/api/v1/services")

json = JSON.parse(response.body)

certs = []

json["items"].each_with_object(certs) do |item, certificates|
  next unless item.dig("metadata", "annotations", "acme/certificate")

  values = item["metadata"]["annotations"]["acme/certificate"]

  begin
    values = JSON.parse(values)
  rescue
  end

  certificates << values
end

puts [{"targets" => certs.flatten}].to_json
