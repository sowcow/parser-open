class Smvstroy
  def initialize
    @host = 'http://www.smvstroy.ru'
    @list_of_links = 'http://www.smvstroy.ru/reestr/reestr.php'
    @required_fields = [
      :inn,
      :name,
      :short_name,
      :legal_address,
      :city,
      :status,
      :ogrn,
      :resolution_date,
      :certificate_number
    ]
    @links = []
    @data = []
  end

  def perform
    collect_links # сбор ссылок
    iterate # собрать ссылки действующих членов

    @data
  end

  private

  def collect_links
    Capybara.visit @list_of_links

    Capybara.find '#ext-gen13-gp-region-Алтайский\20 край-bd > div.x-grid3-row.x-grid3-row-first > table > tbody > tr > td.x-grid3-col.x-grid3-cell.x-grid3-td-2.white-space-normal > div > a > span'
    # .find waits by default. selector is so exact to escape ambiguous matching error. 
    links = Capybara.all '.x-grid3-body tr a'
    links.each do |link|
      @links.push "#{@host}#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start scraping #{link}"
      begin
        Capybara.visit link
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        Capybara.find '#the-table'
        begin
          value = self.send m
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp
      puts 'scraped'
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = Capybara.first(:xpath, '//tr[contains(.,"Инн")]/td[2]').text
  end

  def ogrn
    raw = Capybara.first(:xpath, '//tr[contains(.,"Огрн")]/td[2]').text
  end

  def short_name
    '-'
  end

  def name
    raw = Capybara.first('#pag_title').text
  end

  def city
    raw = Capybara.first(:xpath, '//tr[contains(.,"Адрес")]/td[2]').text

    test1 = raw.match /\b((пос|гор|пгт|рп|п.г.т.)\. [А-Яа-я\- ]+)\b/
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
    raw = Capybara.first(:xpath, '//tr[contains(.,"Адрес")]/td[2]').text
  end

  def resolution_date
    Capybara.find('#ext-gen25').click
    raw = Capybara.first(:xpath, '//tr[contains(.,"Дата")]/td[2]').text
  end

  def certificate_number
    raw = Capybara.first(:xpath, '//tr[contains(.,"Номер свидетельства")]/td[2]').text
  end

  def status
    raw = Capybara.first(:xpath, '//tr[contains(.,"статус членства")]/td[2]').text
    return :w if raw[/состоит/i]
    return :e if raw[/исключен/i]
  end

end