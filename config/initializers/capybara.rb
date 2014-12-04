require 'capybara/poltergeist'

Capybara.register_driver :selenium do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: false,
   # phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes'],
    timeout: 90)
end

Capybara.default_driver = :selenium
Capybara.javascript_driver = :selenium
Capybara.run_server = false
