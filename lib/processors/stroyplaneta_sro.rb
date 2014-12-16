class StroyplanetaSro
  def initialize
    @base = 'http://stroyplaneta-sro.ru'
    @list_of_links = 'http://stroyplaneta-sro.ru/united-builders_partnership_registry.html'
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

    @data
  end

  private
  def collect_links
    doc = Nokogiri::HTML(open(@list_of_links))
    org_tens_raw = doc.css('div.container > div.sixteen.columns > p:nth-child(3)').text
    org_tens = org_tens_raw[/\d+/].to_i / 10 #десятки организаций
    pages_of_links = []
    (org_tens+1).times do |n| #+1 for 'offset=110' page
      pages_of_links.push "http://stroyplaneta-sro.ru/united-builders_partnership_registry.html?offset=#{n*10}"
    end

    pages_of_links.each do |page_of_links|
      doc = Nokogiri::HTML(open(page_of_links))
      links = doc.css('table[summary="Реестр организаций"] a')
      links.each { |link| @links.push "#{@base}/#{link['href']}" }
    end
  end

  def iterate
    @links.each do |link|
      puts "start scraping #{link}"
      begin
        @doc = Nokogiri::HTML(open(link))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m
          # '-' if value.nil?
          # value.strip! if value.is_a? String
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts 'scraped'
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @doc.css('tr')[6].css('td').text
  end

  def ogrn
    raw = @doc.css('tr')[7].css('td').text
  end

  def short_name
    raw = @doc.css('tr')[1].css('td').text
  end

  def name
    raw = @doc.css('tr')[2].css('td').text
  end

  def city
    raw = @doc.css('tr')[10].css('td').text

    test1 = raw.match /\b((пос|гор|пгт|рп|город:)\.? [А-Яа-я\-]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\-]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок) [А-Яа-я\-]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def legal_address
    raw = @doc.css('tr')[10].css('td').text
  end

  def resolution_date
    raw = @doc.css('tr:contains("Дата выдачи свидетельства")').css('td').text
  end

  def certificate_number
    raw = @doc.css('tr:contains("Номер свидетельства")').css('td').text
  end

  def status
    :w
  end

end