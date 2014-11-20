namespace :dev do
  task :test do
    puts('alive')
  end

  task :console do
    byebug
  end

  task :mysql do
    sources = Source.all

    sources.each do |source|
      puts "#{source.id} #{source.name} #{source.registry_number} #{source.registry_link}"
    end
  end

  task :capybara do
    source = Nasgage.new
    source.perform
  end

  task :manager, :source_id do |t, args|
    manager = Manager.new args[:source_id]
    manager.export
  end

end