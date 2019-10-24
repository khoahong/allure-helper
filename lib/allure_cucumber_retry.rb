AllureCucumber::Formatter.class_eval do
  def start_test
    if @tracker.scenario_name
      if $scenario_name == @tracker.scenario_name
        AllureRubyAdaptorApi::Builder.suites[@tracker.feature_name][:tests][@tracker.scenario_name][:status] = cucumber_status_to_allure_status('undefined')
        @tracker.scenario_name = "#{@tracker.scenario_name} RETRY"
      end
      $scenario_name = @tracker.scenario_name
      @scenario_tags[:feature] = @tracker.feature_name
      @scenario_tags[:story] = @tracker.scenario_name
      AllureRubyAdaptorApi::Builder.start_test(@tracker.feature_name, @tracker.scenario_name, @scenario_tags)
      post_deferred_steps
    end
  end
end