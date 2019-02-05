require 'net/http'
require 'uri'
require 'time'

# Logs events to App Insights in Azure
# Used to get data on how much this tool is actually used
module Telemetry
  APP_INSIGHTS_ENDPOINT = 'https://dc.services.visualstudio.com/v2/track'.freeze
  APP_INSIGHTS_KEY = '5bba4816-4379-4ca4-96a7-cc9fc8967c5f'.freeze
  APP_INSIGHTS_EVENT_TYPE = 'Microsoft.ApplicationInsights.Event'.freeze
  APP_INSIGHTS_BASE_TYPE = 'EventData'.freeze

  # Events
  METATDATA_TO_JSON = 'Metadata to JSON'.freeze
  JSON_TO_MARKDOWN = 'JSON to Markdown'.freeze

  def self.log_metdata_to_json(options = {})
    event_data = {
      ver: 2,
      name: METATDATA_TO_JSON,
      properties: {
        version: options[:version],
        metadata: options[:metadata].nil? ? 'graph.microsoft.com' : options[:metadata]
      }
    }

    post_event event_data
  end

  def self.log_json_to_markdown(options = {})
    event_data = {
      ver: 2,
      name: JSON_TO_MARKDOWN,
      properties: {
        version: options[:version],
        author: options[:author],
        product: options[:product]
      }
    }

    post_event event_data
  end

  def self.post_event(event = {})
    payload = {
      name: APP_INSIGHTS_EVENT_TYPE,
      time: Time.now.utc.iso8601,
      iKey: APP_INSIGHTS_KEY,
      data: {
        baseType: APP_INSIGHTS_BASE_TYPE,
        baseData: event
      }
    }

    puts payload.to_json

    Net::HTTP.post URI(APP_INSIGHTS_ENDPOINT),
                   payload.to_json,
                   'Content-Type' => 'application/json'
  end
end
