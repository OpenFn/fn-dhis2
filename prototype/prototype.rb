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

def describe(credentials, _target)
  # _target would probably be something like trackedEntity, event, etc
  connection = build_connection(JSON.parse(credentials, symbolize_names: true))
  response = connection.get '/demo/api/trackedEntityAttributes.json'
  # For now, assume one page only - so we are only interested in attributes
  tracked_entity_attributes = JSON.parse(response.body, symbolize_names: true)[:trackedEntityAttributes]
  tea_ids = tracked_entity_attributes.map { |tea| tea[:id] }
  JSON.generate(tea_ids)
end

def prepare(schema, message)
  schema_as_hash = JSON.parse(schema)
  message_as_hash = JSON.parse(message)
  tracked_entity_identifier = message_as_hash.keys.first
  organisational_unit = message_as_hash.values.first["orgUnit"]
  attributes = message_as_hash.values.first.inject([]) do |memo, (key,value)|
    if schema_as_hash.include? key # This is a recognised attribute
      memo << {attribute: key, value: value}
    else
      memo
    end
  end
  output = {trackedEntity: tracked_entity_identifier, orgUnit: organisational_unit, attributes: attributes}
  JSON.generate(output)
end

credentials = IO.read(File.join(File.dirname(__FILE__), "..", "credentials.json"))
raw_payload2 = IO.read(File.join(File.dirname(__FILE__), "..", "raw_destination_payload2.json"))
schema = describe(credentials, "doesnotmatter") # Not really a schema at the moment, but for naming consistency

payload2  = prepare(schema, raw_payload2)
response = push(credentials, payload2)

puts
puts "Result of push is HTTP #{response.status}"
puts "New resource location is #{response.headers["location"]}"
