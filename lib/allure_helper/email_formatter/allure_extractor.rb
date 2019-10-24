# AllureExtractor extracts test information from allure's json.
class AllureExtractor
  attr_reader :allure_client

  class << self
    def init(allure_report_url)
      @allure_client = AllureApiHelper.new(allure_report_url)
    end

    def extract_allure_content(config)
      init(config.build_url)
      suite = Suite.new(config)

      begin
        # Fetch the summary of this suite.
        summary = @allure_client.get_summary
        suite.start_time = summary.time.start
        suite.end_time = summary.time.stop
        suite.failed = summary.statistic.failed
        suite.broken = summary.statistic.broken
        suite.skipped = summary.statistic.skipped
        suite.passed = summary.statistic.passed
        suite.total = summary.statistic.total

        detailed = @allure_client.get_suites
        detailed.children.each do |f|
          feature = Feature.new
          feature.name = f.name

          f.children.each do |test|
            tc = TestCase.new(test.name)
            tc.status = test.status
            tc.allure_id = test.uid

            case test.status
            when 'passed'
              feature.passed += 1
            when 'failed'
              feature.failed += 1
            when 'skipped'
              feature.skipped += 1
            when 'unknown'
              feature.skipped += 1
            when 'broken'
              feature.broken += 1
            end

            if tc.status == 'broken'
              tc_details = @allure_client.test_case_details(tc.allure_id)
              link = tc_details.links.find do |link|
                link.type == 'issue'
              end

              unless link.nil?
                unless link&.url.nil?
                  tc.issues << link.url
                  suite.known_issues << link.url
                end
              end
            end

            feature.test_cases[tc.name] = tc
          end

          suite.add_feature(feature)
        end
        suite

      rescue HTTParty::ResponseError => e
        suite.allure_report_not_found = true
        suite
      end
    end

  end
end