require 'bundler'
require 'date'
require 'open-uri'
require 'yaml'
require 'csv'

Bundler.require

require 'active_support/all'
require 'active_record'
require 'mysql2'

Dir.glob('./config/initializers/*.rb').each { |f| require f }
Dir.glob('./lib/*.rb').each { |f| require f }
Dir.glob('./lib/processors/*.rb').each { |f| require f }
Dir.glob('./models/*.rb').each { |f| require f }

Dir.glob('./tasks/*.rake').each { |r| load r }