class SroRos
  def initialize
    @host = 'http://sro-ros.ru'
    @list_link = 'http://sro-ros.ru/register/?SHOWALL_1=1#'
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
    @data = []
  end

  def perform
    collect_links # Сбор ссылок
    iterate # Переход и сбор информации #time

    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_link))
    @links = [] 
    doc.css('.reestr tbody td a').each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        doc = Nokogiri::HTML(open(URI.encode(link)))
        @table = doc.at('.news-detail')
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        value = self.send m #for status symbols
        value = value.strip if value.is_a? String
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts "parsed"
    end
    p @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @table.css('tr')[2].css('td')[1].text
  end

  def short_name
    '-'
  end

  def name
    raw = @table.css('h3').text
  end

  def city
    raw = @table.css('tr')[0].css('td')[1].text
    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок|город) [А-Яа-я\- ]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def status
    raw = @table.css('tr')[9].css('td')[1].text    
    return :w if (raw.include? 'Действует')
    raw
  end

  def resolution_date
    raw = @table.css('tr')[1].css('td')[1].text
  end

  def legal_address
    raw = @table.css('tr')[0].css('td')[1].text
  end

  def certificate_number
    raw = @table.css('tr')[3].css('td')[1].text
  end

  def ogrn
    raw = @table.css('tr')[4].css('td')[1].text
    raw.strip[/\A\d+/]
  end
end

