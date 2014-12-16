class Npgks
  def initialize
    @host = 'http://npgks.ru'
    @list_of_links_w = 'http://npgks.ru/?menu=registry'
    @list_of_links_e = 'http://npgks.ru/?menu=registry&ex=1'

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
    collect_links @list_of_links_w # Сбор ссылок
    collect_links @list_of_links_e
    iterate # Переход и сбор информации #time

    p @data
  end

  private

  def collect_links link
    doc = Nokogiri::HTML(open(link))
    doc.css('#middle>table tr')[0].css('td')[0].css('a').each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start scraping #{link}"
      begin
        doc = Nokogiri::HTML(open(URI.encode(link)))
        @doc = doc.css('#middle > table')
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
          value = self.send(m) #for status symbols
          value = value.strip if value.is_a? String
          tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts 'scraped'
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @doc.xpath('//b[text()="ИНН:"]/following-sibling::text()[1]').text 
  end

  def ogrn
    raw = @doc.xpath('//b[text()="ОГРН:"]/following-sibling::text()[1]').text 
    raw.gsub ',', ''
  end

  def short_name
    raw = @doc.xpath('//b[text()="Сокращенное наименование организации:"]/following-sibling::text()[1]').text
  end

  def name
    raw = @doc.xpath('//b[text()="Полное наименование организации:"]/following-sibling::text()[1]').text 
  end

  def city
    raw = @doc.xpath('//b[text()="Место нахождения юридического лица:"]/following-sibling::text()[1]').text 

    test1 = raw.match /\b((пос|гор|пгт|рп)\.? [А-Яа-я\- ]+)\b/
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
    raw = @doc.xpath('//b[text()="Место нахождения юридического лица:"]/following-sibling::text()[1]').text 
  end

  def status
    raw = @doc.xpath('//b[text()="Статус:"]/following-sibling::text()[1]').text  
    return :w if raw[/действительный член/i]
    return :c if raw[/добровольный выход/i]
    return :e if raw[/исключение/i]
  end

  def resolution_date
    raw = @doc.xpath('//b[text()="Сведения о выданных допусках:"]/following-sibling::text()').text 
    raw.scan(/\d{4}\-\d{2}\-\d{2}/).last
  end

  def certificate_number
    raw = @doc.xpath('//b[text()="Сведения о выданных допусках:"]/following-sibling::a[last()]').text
  end

end