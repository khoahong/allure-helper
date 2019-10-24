module AllureHelper
  class Configuration
    attr_accessor :build_url, :suite_name
    attr_accessor :base_dir, :result_dir, :properties_file, :attachment_dir, :environment_file, :allure_result_file
  end
end
