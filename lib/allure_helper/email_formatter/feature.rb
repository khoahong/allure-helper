class Feature
  attr_accessor :name, :test_cases, :passed, :failed, :skipped, :broken, :feature_id

  def initialize
    @test_cases = {}
    @passed = 0
    @failed = 0
    @skipped = 0
    @broken = 0
  end

  def add_test_case(test_case)
    test_name = get_test_case_name(test_case.source)
    tc = TestCase.new(test_name)
    tc.add_issues(test_case)
    test_cases[test_name] = tc
  end

  def update_test_status(event)
    test_cases[get_test_case_name(event.test_case.source)].status = event.result.to_sym

    case event.result.to_sym.to_s
    when 'passed'
      @passed += 1
    when 'failed'
      @failed += 1
    when 'skipped'
      @skipped += 1
    when 'pending'
      @skipped += 1
    when 'undefined'
      @broken += 1
    end
  end

  def get_test_case_name(source)
    source.each do |element|
      if element.is_a? Cucumber::Core::Ast::ScenarioOutline
        return element.location
      elsif element.is_a? Cucumber::Core::Ast::Scenario
        return element.name
      end
    end
  end
end
