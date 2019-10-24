
require 'allure-helper/version'
require 'allure_helper/configuration'
require 'allure_helper/api_html_builder'
module AllureHelper
  ALLURE_TYPE_TXT ||= '.txt'
  ALLURE_TYPE_JSON ||= '.json'
  ALLURE_TYPE_XML ||= '.xml'
  ALLURE_TYPE_PNG ||= '.png'
  ALLURE_TYPE_HTML ||= '.html'

  class << self
    def configure
      yield config
    end

    # overriding Pending error to_s to render message.
    # now to skip a step, add pending(<skip reason>) in your step definition
    Cucumber::Core::Test::Result::Pending.class_eval do
      def to_s
        message
      end
    end

    Cucumber::Formatter::LegacyApi::TableRowPrinter.class_eval do
      def step_invocation(step_invocation, source)
        result = source.step_result
        step_invocation.messages.each { |message| formatter.puts(message) }
        step_invocation.embeddings.each { |embedding| embedding.send_to_formatter(formatter) }
        @failed_step = step_invocation if result.status == :failed
        @status = step_invocation.status unless already_failed?
        status_tracking(step_invocation, source) if source.step.instance_variable_get('@outline_step').text == source.scenario_outline&.steps&.last&.text
      end

      def status_tracking(step_invocation, source)
        bug_tag = (source.scenario_outline.tags + source.examples_table.tags).find { |t| t.name.include? AllureCucumber::Config.issue_prefix }
        if bug_tag
          if @status == :passed
            @status = :failed
            step_invocation.exception = Exception.new("Test is broken due to an existing defect - #{bug_tag.name}")
            @failed_step = step_invocation
          else
            @status = :undefined
          end
        end
      end
    end

    # Hack to update cucumber test case status when the scenario has issue tag.
    #
    Cucumber::Core::Test::Runner.class_eval do
      def test_case(test_case, &descend)
        @running_test_case = Cucumber::Core::Test::Runner::RunningTestCase.new
        @running_test_step = nil
        issue_prefix = AllureCucumber::Config.issue_prefix
        scenario_tags = test_case.tags
        AllureHelper.process_custom_tags(scenario_tags, issue_prefix)
        event_bus.test_case_started(test_case)
        descend.call(self)
        # Update Cucumber test case status
        # Check for issue tag post scenario execution
        # If test has passed inspite of the issue tag being present,
        # fail the test case to notify user to remove the tag
        # Else mark the test as undefined. (undefined changed to broken in allure)
        #--------------------------------------------------#

        bug_tag = scenario_tags.find { |t| t.name.include? issue_prefix }
        if bug_tag
          if running_test_case.result.passed?
            error = StandardError.new('Issue tag found, But test passed')
            error.set_backtrace([])
            running_test_case.failed(Cucumber::Core::Test::Result::Failed.new(running_test_case.result.duration, error))
          else
            running_test_case.pending("Test is broken due to existing defect: #{bug_tag.name}", Cucumber::Core::Test::Result::Undefined.new)
          end
        end
        #--------------------------------------------------#
        event_bus.test_case_finished(test_case, running_test_case.result)
        self
      end
    end

    def config
      @config ||= Configuration.new.tap do |config|
        config.result_dir = 'gen/allure-results'
        config.properties_file = 'allure.properties'
        config.environment_file = 'environment.properties'
        config.attachment_dir = 'allure_attachments'
        config.allure_result_file = 'allure_result.txt'
      end
    end

    def attach_file(file_path, file_name, file_type = ALLURE_TYPE_TXT)
      file = "#{file_path}/#{file_name}#{file_type}"
      AllureCucumber.attach_file(file_name, File.new(file)) if File.exist?(file)
      LoggerHelper.print_step_info "Attachment created! Filename: #{file_name} "
    end

    def attach_content(file_name, content, file_type = ALLURE_TYPE_TXT, display_content = true)
      file_name = file_name.tr(' ', '_').delete('|').tr('/', '_')[0..60]
      file_name = "#{file_name}_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}"
      File.open("#{config.attachment_dir}/#{file_name}#{file_type}", 'w+') do |file|
        file.write("#{content}\n\n")
      end

      AllureHelper.attach_file(config.attachment_dir, file_name, file_type) unless feature_tracker.nil?

      LoggerHelper.print_step_info "Attachment content: #{content}" if display_content
    end

    # works only for httpparty response
    def attach_rest_api_log(file_name, response)
      content = ApiHtmlBuilder.new.build_html response
      file_name = file_name.tr(' ', '_').delete('|').tr('/', '_')[0..60]
      File.open("#{config.attachment_dir}/#{file_name}#{ALLURE_TYPE_HTML}", 'w+') do |file|
        file.write("#{content}\n\n")
      end
      AllureHelper.attach_file(config.attachment_dir, file_name, ALLURE_TYPE_HTML) unless feature_tracker.nil?
    end

    def log_file_list
      log_file_list = []
      allure_attachments_path = "#{config.base_dir}/#{config.attachment_dir}"
      Dir.entries(allure_attachments_path).reject { |f| File.directory? f }.each do |file_name|
        next if file_name == '.gitkeep'

        file_path = "#{allure_attachments_path}/#{file_name}"
        next if File.directory? file_path

        log_file_list.push(file_path)
      end
      log_file_list
    end

    def update_tracker_step(step_name)
      feature_tracker.step_name = step_name unless feature_tracker.nil?
    end

    def generate_step_log_and_report(scenario, step_name, report_dir)
      # this workaround is for to not use allure cucumber formatter if it is not enabled through --format
      is_allure_report_enabled = !feature_tracker.nil?
      return unless is_allure_report_enabled

      file_path = ReportHelper.generate_report_directory(config.base_dir, report_dir, scenario, step_name)
      log_file_list = AllureHelper.log_file_list
      log_file_list.each do |log_file|
        file_content = File.read(log_file)
        file_ext = File.extname(log_file)
        report_file = ReportFile.new(file_name: File.basename(log_file, file_ext), file_path: file_path, file_extension: file_ext, file_content: file_content)
        ReportHelper.generate_report_for_step(scenario, file_path, report_file)
        FileUtils.rm(log_file)
      end
    end

    # generate allure properties file
    #  ex: hash for jira issues link
    # {'allure.issues.tracker.pattern' => 'https://libertywireless.atlassian.net/browse/%s'}
    #
    def generate_allure_properties_file(properties = {})
      properties_file_path = "#{config.base_dir}/#{config.result_dir}/#{config.properties_file}"
      write_to_properties_file(properties_file_path, properties)
    end

    # generate enviroment information to be printed in allure report
    # ex: hash with env info
    # { 'Environment' => 'staging',
    #   'Service End Point' => 'https://rain.cirlces.asia',
    #   'Browser' => 'Chrome' }

    def generate_environment_information(env_info = {})
      properties_file_path = "#{config.base_dir}/#{config.result_dir}/#{config.environment_file}"
      write_to_properties_file(properties_file_path, env_info)
    end

    def write_to_properties_file(properties_file_path, properties = {})
      File.delete(properties_file_path) if File.exist?(properties_file_path)

      properties.each do |key, value|
        File.open(properties_file_path, 'a') do |f|
          f.puts "#{key}=#{value}"
        end
      end
    rescue Exception => e
      LoggerHelper.log_step_info "Exception message: #{e.message}"
      LoggerHelper.log_step_info 'Something went wrong while writing to properties file, skip it and continue running tests...'
    end

    def feature_tracker
      AllureCucumber::FeatureTracker.tracker
    end

    # Replaces country or environment specific bug tags with normal ones.
    # Discards the bugs for the other countries or environment.

    def process_custom_tags(scenario_tags, issue_prefix)
      partial_prefix = issue_prefix.sub('@', '')
      remove_code(scenario_tags, VENTURE, partial_prefix)
      remove_code(scenario_tags, ENVIRONMENT, partial_prefix)
      scenario_tags.reject! { |tag| tag.name.include?("_#{partial_prefix}") }
    end

    def remove_code(scenario_tags, code, prefix)
      scenario_tags.each { |tag| tag.instance_eval("@name = '#{tag.name.sub("@#{code.upcase}_#{prefix}", "@#{prefix}")}'") }
    end
  end
end
