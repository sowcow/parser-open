require 'capybara/poltergeist'

Capybara.register_driver :phantomjs do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: false,
   	phantomjs_options: ['--load-images=no', '--ignore-ssl-errors=yes'],
    timeout: 90)
end

Capybara.default_driver = :phantomjs
Capybara.javascript_driver = :phantomjs
Capybara.run_server = false
