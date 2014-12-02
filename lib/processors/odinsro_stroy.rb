class OdinsroStroy
  def initialize
    @host = 'http://odinsro-stroy.ru'
    @list_link = 'http://odinsro-stroy.ru/reestr'
    @data_link_template = ''
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
    iterate # Переход и сбор информации
    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_link))
    @links = [] 
    doc.css('div#maincontent li:not(:first-child) a').each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
    @links
  end

  def iterate
    @links.each do |link|
      puts "openinig #{link}"
      begin
        @doc = Nokogiri::HTML(open(URI.encode(link)))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send(m) #for status symbols
          value = value.strip if value.is_a? String
          tmp.merge! m => value
        rescue
          tmp.merge!(m => '-') #if there was an error in data retrieval, pretend it's -
        end 
      end

      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @doc.css('li:not(:first-child) td.t5').text
    raw.split('/')[0]
  end

  def short_name
    raw = @doc.css('li:not(:first-child) td.t3').text
    raw.split('/')[1]
  end

  def name
    raw = @doc.css('li:not(:first-child) td.t3').text
    raw.split('/')[0]
  end

  def city
    raw = @doc.css('li:not(:first-child) td.t4').text
    test1 = raw[/[пгс][.]\s?[А-Яа-я\- ]+/]
    test2 = raw[/,\s?[А-Яа-я\- ]+\s[гп].?\w?,/]
    test4 = raw[/,\s?[А-Яа-я\- ]+/]
    city =  
      if test1
        test1.to_s
      elsif test2
        test2.to_s
      elsif test4
        test3.to_s
      end

    city.gsub(',', '')
  end

  def status
    raw = @doc.css('li:not(:first-child) td.t7').text    
    return :w if raw.include? '-------'
    return :e if (raw.include? 'Исключен') || (raw.include? 'Выбыл')
    '-'
  end

  def resolution_date
    raw = @doc.css('tr:nth-child(8) td:nth-child(2)').text
    raw[/\d{2}\.\d{2}\.\d{4}/] #gets first date from td
  end

  def legal_address
    raw = @doc.css('li:not(:first-child) td.t4').text
  end

  def certificate_number
    raw = @doc.css('tr:nth-child(8) td:nth-child(2)').text
    raw[/№\s?[\w\.\-А-Яа-я]+/]
  end

  def ogrn
    raw = @doc.css('li:not(:first-child) td.t5').text
    raw.split('/')[1]
  end
end

