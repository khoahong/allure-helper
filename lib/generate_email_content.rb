require 'require_all'

require_all 'lib/allure_helper'

env = ENV["ENVIRONMENT"]
jenkins_url = ENV['JENKINS_URL']
job = ENV["JOB"]
suites = []


config = AllureHelper::Configuration.new.tap do |config|
  config.build_url = URI::encode "#{jenkins_url}/job/#{job}/allure"
  config.suite_name = 'abc'
end

suites << AllureExtractor.extract_allure_content(config)

html = EmailReport.new.build_email(suites, env)

file_path = Pathname.new(Dir.pwd).join(EmailFormatter.email_config.final_output)
File.open(file_path, 'w') do |f|
  f.write(html)
end
