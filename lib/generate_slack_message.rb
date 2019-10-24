require 'require_all'
require_all 'lib/allure_helper'

jenkins_url = ENV['JENKINS_URL']
job = ENV['JOB']

config = AllureHelper::Configuration.new.tap do |config|
  config.build_url = URI::encode "#{jenkins_url}/job/#{job}/allure"
  config.suite_name = job
  config.allure_result_file = 'allure_result.txt'
end

suite = AllureExtractor.extract_allure_content(config)

file_path = Pathname.new(Dir.pwd).join(config.allure_result_file)
content = "Total: #{suite.total}, Passed: #{suite.passed}, Failed: #{suite.failed}, Broken: #{suite.broken}, Skipped: #{suite.skipped}"
File.open(file_path, 'w') { |f| f.write(content) }
