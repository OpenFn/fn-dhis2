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

class TrackedEntity
  def self.push(credentials, message)
    connection = build_connection(JSON.parse(credentials, symbolize_names: true))
    response = connection.post  do |req|
      req.url '/demo/api/trackedEntityInstances'
      req.headers['Content-Type'] = 'application/json'
      req.body = message
    end
  end

  def self.describe(credentials, _target)
    # _target would probably be something like trackedEntity, event, etc
    connection = build_connection(JSON.parse(credentials, symbolize_names: true))
    response = connection.get '/demo/api/trackedEntityAttributes.json'
    # For now, assume one page only - so we are only interested in attributes
    tracked_entity_attributes = JSON.parse(response.body, symbolize_names: true)[:trackedEntityAttributes]
    tea_ids = tracked_entity_attributes.map { |tea| tea[:id] }
    JSON.generate(tea_ids)
  end

  def self.prepare(schema, message)
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
end

class DataSet
  def self.extract_dataset_id(payload)
    dataset = JSON.parse(payload)
    dataset.keys.first
  end

  def self.describe(credentials, dataset_id)
    connection = build_connection(JSON.parse(credentials, symbolize_names: true))
    response = connection.get "/demo/api/dataElements.json?filter=dataSets.id:eq:" + dataset_id
    data_elements = JSON.parse(response.body, symbolize_names: true)[:dataElements]
    JSON.generate(data_elements.map { |d| d[:id] })
  end

  def self.prepare(schema, message)
    schema_as_hash = JSON.parse(schema)
    message_as_hash = JSON.parse(message)
    data_set_id = message_as_hash.keys.first
    organisational_unit = message_as_hash.values.first["orgUnit"]
    period = message_as_hash.values.first["period"]
    completeData = message_as_hash.values.first["completeData"]
    data_values = message_as_hash.values.first.inject([]) do |memo, (key,value)|
      if schema_as_hash.include? key # This is a recognised attribute
        memo << {dataElement: key, value: value}
      else
        memo
      end
    end
    output = {dataSet: data_set_id, orgUnit: organisational_unit, period: period, completeData: completeData, dataValues: data_values}
    JSON.generate(output)
  end

  def self.push(credentials, message)
    connection = build_connection(JSON.parse(credentials, symbolize_names: true))
    response = connection.post  do |req|
      req.url '/demo/api/dataValueSets'
      req.headers['Content-Type'] = 'application/json'
      req.body = message
    end
  end
end

class AnonymousEvent
  def self.describe(credentials, dataset_id)
    JSON.generate({})
  end

  def self.prepare(schema, message)
    message_as_hash = JSON.parse(message)
    event = message_as_hash["event"]
    raw_data_values = event.delete "dataValues"
    transformed_data_values = raw_data_values.inject([]) do |memo, (k,v)|
      memo << {"dataElement" => k, "value" => v}
    end
    JSON.generate(event.merge("dataValues" => transformed_data_values))
    JSON.generate(event)
  end

  def self.push(credentials, message)
    connection = build_connection(JSON.parse(credentials, symbolize_names: true))
    response = connection.post  do |req|
      req.url '/demo/api/events'
      req.headers['Content-Type'] = 'application/json'
      req.body = message
    end
  end
end

class AggregatedEvent
  def self.describe
  end

  def self.push(credentials, message)
    message_as_hash = JSON.parse(message)
    raw_event = message_as_hash["event"]
    associated_tracked_entities = raw_event["instances"].inject([]) do |memo, instance_set|
      raw_instance_data = JSON.generate({ raw_event["trackedEntity"] => instance_set })
      schema = TrackedEntity.describe(credentials, "doesnotmatter")
      payload = TrackedEntity.prepare(schema, raw_instance_data)
      response = TrackedEntity.push(credentials, payload)
      data = JSON.parse(response.body)
      memo << data["response"]["reference"]
    end
    associated_tracked_entities.each do |ate_id|
      data = {
        "trackedEntityInstance" => ate_id,
        "orgUnit" => raw_event["orgUnit"],
        "program" => raw_event["program"]
      }

      connection = build_connection(JSON.parse(credentials, symbolize_names: true))
      response = connection.post  do |req|
        req.url '/demo/api/enrollments'
        req.headers['Content-Type'] = 'application/json'
        req.body = JSON.generate(data)
      end

      puts "/////////////////////////////////////////////////////////////////////////////////////"
      p data
      p response
      puts "/////////////////////////////////////////////////////////////////////////////////////"
      linked_event = {
        "event" => {
          "program" => raw_event["program"],
          "programStage" => raw_event["programStage"],
          "orgUnit" => raw_event["orgUnit"],
          "eventDate" => raw_event["eventDate"],
          "status" => raw_event["status"],
          "storedBy" => raw_event["storedBy"],
          "coordinate" => raw_event["coordinate"],
          "trackedEntityInstance" => ate_id,
          "dataValues" => {}
        }
      }

      schema = AnonymousEvent.describe(credentials, "doesnotmatter")
      payload = AnonymousEvent.prepare(schema, JSON.generate(linked_event))
      response =  AnonymousEvent.push(credentials, payload)

      puts "**************************************************************************************"
      p response
      puts "***************************************************************************************"
    end
  end
end

credentials = IO.read(File.join(File.dirname(__FILE__), "..", "credentials.json"))

puts "Starting with tracked entities"
puts
raw_payload2 = IO.read(File.join(File.dirname(__FILE__), "..", "raw_destination_payload2.json"))
schema = TrackedEntity.describe(credentials, "doesnotmatter") # Not really a schema at the moment, but for naming consistency

payload2  = TrackedEntity.prepare(schema, raw_payload2)
response = TrackedEntity.push(credentials, payload2)

puts
puts "Tracked Entity"
puts "Result of push is HTTP #{response.status}"
puts "New resource location is #{response.headers["location"]}"
p JSON.parse(response.body)

#  Now try and import datavalues

puts
puts "Starting with data sets"
puts

raw_payload1 = IO.read(File.join(File.dirname(__FILE__), "..", "raw_destination_payload1.json"))
destination_payload1 = IO.read(File.join(File.dirname(__FILE__), "..", "destination_payload1.json"))

dataset_id = DataSet.extract_dataset_id(raw_payload1)
schema = DataSet.describe(credentials, dataset_id)
payload1 = DataSet.prepare(schema, raw_payload1)
response = DataSet.push(credentials, payload1)

puts
puts "Data Set"
puts "Result of push is HTTP #{response.status}"
p JSON.parse(response.body)

# AnonymousEvents next - first a standalone event
#

puts
puts "Starting with anonymous events"
puts

raw_payload3 = IO.read(File.join(File.dirname(__FILE__), "..", "raw_destination_payload3.json"))
destination_payload3 = IO.read(File.join(File.dirname(__FILE__), "..", "destination_payload3.json"))

schema = AnonymousEvent.describe(credentials, "doesnotmatter")
payload3 = AnonymousEvent.prepare(schema, raw_payload3)
response =  AnonymousEvent.push(credentials, payload3)

puts
puts "AnonymousEvent without registration"
puts "Result of push is HTTP #{response.status}"
puts "New event location is #{response.headers["location"]}"
p response.body

puts
puts "Starting with an aggregated event"
puts

raw_payload4 = IO.read(File.join(File.dirname(__FILE__), "..", "raw_destination_payload4.json"))
AggregatedEvent.push(credentials, raw_payload4)
