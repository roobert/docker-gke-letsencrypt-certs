#!/usr/bin/env ruby

require "httparty"
require "json"
require "diplomat"

Diplomat.configure do |config|
  config.url = "http://consul-consul:8500"
end

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

def service(address)
  {
    "ID"      => address,
    "Name"    => address,
    "Address" => "127.0.0.1",
    "Tags"    => [ "gke-ssl-cert-cn" ]
  }
end

def defunct_services
  cert_cache = certificates
  Diplomat::Service.get_all.each_pair.reject do |service, tags|
    (cert_cache.include?(service.to_s) && tags.include?("gke-ssl-cert-cn")) \
      || !tags.include?("gke-ssl-cert-cn")
  end
end

certificates.each do |address|
  puts "registering: #{address}"
  Diplomat::Service.register(service(address))
end

defunct_services.to_h.each do |service, _|
  puts "deregistering: #{service}"
  Diplomat::Service.deregister(service.to_s)
end
