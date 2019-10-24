require_relative 'suite'
require_relative 'test_case'
require_relative 'feature'
require_relative 'email_report'
class EmailFormatter
  class Configuration
    attr_accessor :env, :suite_name, :build_url, :final_output
  end

  class << self
    def configure
      yield email_config
    end

    def email_config
      @config ||= EmailFormatter::Configuration.new.tap do |config|
        config.final_output = 'out.html'
      end
    end
  end

  def initialize(config)
    EmailFormatter.email_config.final_output = config.to_hash[:out_stream] unless config.to_hash[:out_stream].is_a? STDOUT.class
    @suite = Suite.new(EmailFormatter.email_config)
    config.on_event :test_case_finished, &method(:on_test_case_finished)
    config.on_event :test_run_started, &method(:on_test_run_started)
    config.on_event :test_run_finished, &method(:on_test_run_finished)
  end

  def on_test_run_started(event)
    event.test_cases.each do |test_case|
      feature = @suite.get_feature(test_case.source[0].name)
      feature.add_test_case(test_case)
    end
    @suite.start_time = Time.now
  end

  def on_test_case_finished(event)
    feature = @suite.get_feature(event.test_case.source[0].name)
    feature.update_test_status(event)
  end

  def on_test_run_finished(_event)
    @suite.end_time = Time.now
    @suite.update_summary
    html = EmailReport.new.build_email([@suite], ENV["ENVIRONMENT"])
    file_path = Pathname.new(Dir.pwd).join(EmailFormatter.email_config.final_output)
    File.open(file_path, 'w') { |f| f.write(html) }
    puts file_path
    puts File.open(file_path) { |f| data = f.read }
  end
end
