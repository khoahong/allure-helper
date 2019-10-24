require 'httparty'

class Job
  attr_reader :name, :alias_name, :build_number, :url

  def initialize(name, alias_name, build_number, url)
    @name = name
    @alias_name = alias_name
    @build_number = build_number
    @url = url
  end
end

class JobParser
  include HTTParty

  attr_reader :parent_build_url, :jobs, :jenkins_url, :upstream_build_url

  def initialize(parent_build_url)
    @parent_build_url = parent_build_url
    @jenkins_url = ENV["JENKINS_URL"]
    @jobs = []
  end

  def parse
    response = self.class.get("#{@parent_build_url}/api/json")
    raise "Unable to get upstream build json" unless response.success?

    json = JSON.parse(response.to_s, object_class: OpenStruct)
    @jobs = json["subBuilds"].map do |build|
      Job.new(build["jobName"],
              build["jobAlias"],
              build["buildNumber"],
              "#{@jenkins_url}#{build["url"]}")
    end

  end
end
