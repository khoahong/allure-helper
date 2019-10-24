# AllureHelper

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/allure_helper`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'allure_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install allure_helper

## Usage

* Firstly, require it in your env.rb file: require 'allure_helper'
* Config the base dir: 
```ruby
AllureHelper.configure do |c|
  c.base_dir = 'your_project_dir'
  c.attachment_dir = 'allure_attachments'
end

```
* Before block code in hooks.rb:
```ruby
Before do |scenario|
  @step_index = 0
  @tests_steps = scenario.test_steps
  @current_step_name = @tests_steps[@step_index].to_s
end
```

* AfterStep block code in hooks.rb:
```ruby
AfterStep do
    # It will get all files in AllureHelper.config.attachment_dir and attach to current step in the report
    AllureHelper.generate_step_log_and_report(@scenario, @current_step_name, AllureHelper.config.attachment_dir)
    @step_index += 2
    @current_step_name = @tests_steps[@step_index].to_s
end
```

* To attach a file: just create this file inside `AllureHelper.config.attachment_dir`

* To attach a debug info: 
```ruby
AllureHelper.attach_content('Attachment title', 'debug content', AllureHelper::ALLURE_TYPE_TXT, false)
```
