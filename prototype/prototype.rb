#!/usr/bin/env ruby
require 'faraday'
require 'json'

def build_connection(credentials)
  conn = Faraday.new(url: credentials[:host]) do |faraday|
    faraday.request :url_encoded
    faraday.response :logger # TODO Prolly not for prod though :)
    faraday.adapter Faraday.default_adapter
  end
  conn.basic_auth(credentials[:username], credentials[:password])
  conn
end

def push(credentials, message)
  connection = build_connection(JSON.parse(credentials, symbolize_names: true))
  response = connection.post  do |req|
    req.url '/demo/api/trackedEntityInstances'
    req.headers['Content-Type'] = 'application/json'
    req.body = message
  end
end

credentials = IO.read(File.join(File.dirname(__FILE__), "..", "credentials.json"))
payload2 = IO.read(File.join(File.dirname(__FILE__), "..", "destination_payload2.json"))

p push(credentials, payload2)
