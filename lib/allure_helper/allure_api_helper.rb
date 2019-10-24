# frozen_string_literal: true
require 'httparty'

class AllureApiHelper
  include HTTParty

  def initialize(base_uri)
    self.class.base_uri(base_uri)
  end

  def default_headers
    { 'Content-Type': 'application/json' }
  end

  # Process the incoming response.
  # Raise an error if the response code is not 200.
  def process_response(response)
    if response.code != 200
      raise HTTParty::ResponseError.new "response code: #{response.code}"
    end

    JSON.parse(response.to_s, object_class: OpenStruct)
  rescue JSON::ParserError => e
    response.body
  end

  def get_summary
    process_response self.class.get('/widgets/summary.json', headers: default_headers)
  end

  def get_suites
    process_response self.class.get('/data/suites.json', headers: default_headers)
  end

  def test_case_details(test_case_id)
    process_response self.class.get("/data/test-cases/#{test_case_id}.json", headers: default_headers)
  end
end
