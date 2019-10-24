require 'require_all'

require_all 'lib/allure_helper'

env = ENV["ENVIRONMENT"]
parent_build_url = ENV["PARENT_BUILD_URL"]

jobs = JobParser.new(parent_build_url).parse

suites = []
jobs.each do |job|
  next if job.name == "Email-Reporting-Test" || job.alias_name == "EXCLUDE_FROM_EMAIL_REPORTING"

  config = AllureHelper::Configuration.new.tap do |config|
    config.build_url = URI::encode("#{job.url}allure")
    config.suite_name = job.name.to_s + (job.alias_name == "" ? "" : " (#{job.alias_name})").to_s
  end

  suites << AllureExtractor.extract_allure_content(config)
end

html = EmailReport.new.build_email(suites, env)

file_path = Pathname.new(Dir.pwd).join(EmailFormatter.email_config.final_output)
File.open(file_path, 'w') do |f|
  f.write(html)
end
