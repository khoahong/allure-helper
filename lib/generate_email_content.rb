require 'require_all'

require_all 'lib/allure_helper'

env = ENV["ENVIRONMENT"]
build_url = "#{ENV["BUILD_URL"]}allure"
suites = []


config = AllureHelper::Configuration.new.tap do |config|
  config.build_url = URI::encode(build_url)
  config.suite_name = 'abc'
end

suites << AllureExtractor.extract_allure_content(config)

html = EmailReport.new.build_email(suites, env)

file_path = Pathname.new(Dir.pwd).join(EmailFormatter.email_config.final_output)
File.open(file_path, 'w') do |f|
  f.write(html)
end
