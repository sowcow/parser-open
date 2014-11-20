# Main
class Manager
  attr_accessor :data

  def initialize(source_id)
    @source = Source.find(source_id)
    @processor = Object.const_get(@source[:processor]).new if Object.const_defined?(@source[:processor])
    @data = @processor.perform
  end

  def export(to = :mysql)
    Exporter.new(to, @data, @source)
  end

  def finalize
    Capybara.session.driver.quit
  end
end
