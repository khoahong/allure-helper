require 'erb'

class EmailReport
  TEMPLATE_FILEPATH = __dir__ + '/email_template.erb'
  CHART_API_URL = 'https://chart.googleapis.com'

  attr_accessor :suites, :test_environment, :chart_url

  def build_email(suites, test_environment)
    @suites = suites
    @test_environment = test_environment
    @chart_url = build_chart_url

    @suites.each do |suite|
      if suite.known_issues.size > 0
        @has_known_issues = true
        break
      end
    end

    # Read and build the template file.
    @template = File.read(TEMPLATE_FILEPATH)
    ERB.new(@template, nil, '-').result(binding)
  end

  def build_chart_url
    passed = 0
    failed = 0
    skipped = 0
    broken = 0
    @suites.each do |suite|
      passed += suite.passed
      failed += suite.failed
      skipped += suite.skipped
      broken += suite.broken
    end
    CHART_API_URL + "/chart?chs=450x250&chd=t:#{passed},#{failed},#{skipped},#{broken}&cht=p3&chl=Passed|Failed|Skipped|Broken&chma=50,50,50,50&chco=518601,fd2b3b,b1b1b1,fde200&chdl=#{passed}|#{failed}|#{skipped}|#{broken}&chof=png"
  end
end
