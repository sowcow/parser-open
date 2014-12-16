require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: false,
    phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes'],
    timeout: 90)
end

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.run_server = false

Capybara.default_wait_time = 10