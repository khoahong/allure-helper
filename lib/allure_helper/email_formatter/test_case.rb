class TestCase
  attr_accessor :name, :status, :issues, :allure_id

  def initialize(name)
    @name = name
    @issues = []
  end

  def add_issues(test_case)
    test_case.source[1].tags.each do |tag|
      if tag.name.include? AllureCucumber::Config.issue_prefix
        @issues.push(tag.name.gsub(AllureCucumber::Config.issue_prefix, ''))
      end
    end
  end
end
