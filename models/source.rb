# Model-like storage for sources
class Source < ActiveRecord::Base
  has_many :companies
end
