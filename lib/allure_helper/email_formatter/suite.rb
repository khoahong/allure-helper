class Suite
  attr_accessor :name, :features, :start_time, :end_time, :failed, :broken, :skipped, :passed, :total
  attr_accessor :allure_report_url, :allure_report_not_found, :known_issues

  def initialize(config)
    @name = config.suite_name
    # @test_env = config.env
    @allure_report_url = config.build_url
    @allure_report_not_found = false
    @known_issues = []
    @features = {}
    @start_time = 0
    @end_time = 0
    @failed = 0
    @broken = 0
    @skipped = 0
    @passed = 0
    @total = 0
  end

  def get_feature(feature_name)
    features[feature_name] ||= Feature.new
  end

  def add_feature(feature)
    features[feature.name] = feature
  end

  def update_summary
    features.each_value do |feature|
      @passed += feature.passed
      @failed += feature.failed
      @skipped += feature.skipped
      @broken += feature.broken
    end
    @total = @passed + @failed + @skipped + @broken
  end
end
