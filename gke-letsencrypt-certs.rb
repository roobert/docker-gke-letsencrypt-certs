#!/usr/bin/env ruby

require "httparty"
require "json"

host = ENV["KUBERNETES_SERVICE_HOST"]
port = ENV["KUBERNETES_PORT_443_TCP_PORT"]

#curl -v --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes/

def certificates
  response = HTTParty.get("https://#{host}:#{port}/api/v1/services")

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

puts [{ "targets" => certificates.flatten }].to_json
