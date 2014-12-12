class Smvstroy
  def initialize
    @host = 'http://www.smvstroy.ru'
    @list_of_links = 'http://www.smvstroy.ru/reestr/reestr.php'
    @required_fields = [
      :inn,
      :name,
      :short_name,
      :city,
      :status,
      :resolution_date,
      :legal_address,
      :certificate_number,
      :ogrn
    ]
    @links = []
    @data = []
  end

  def perform
    collect_links # сбор ссылок
    iterate # собрать ссылки действующих членов

    p @data
  end

  private

  def collect_links
    Capybara.visit @list_of_links

    while true do #because should have_css attempts failed
      Capybara.has_css?('.x-grid3-body tr a') ? break : sleep(0.2)
    end

    links = Capybara.all('.x-grid3-body tr a')
    links.each do |link|
      @links.push "#{@host}#{link['href']}"
    end
    p @links
  end

  def iterate
    @links[0..3].each do |link|
      puts "openinig #{link}\n\n"
      begin
        Capybara.visit link
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m
          value = value.nil? ? '-' : value.strip
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    sleep 3
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def ogrn
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def short_name
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def name
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def city
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text

    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок) [А-Яа-я\- ]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def legal_address
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def resolution_date
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

  def certificate_number
    raw = Capybara.first('#the-table tr:nth-child(2) td:nth-child(2)').text
  end

end

# Smvstroy.new.perform