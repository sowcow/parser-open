class Sibrp
  def initialize
    @host = 'http://www.sibrp.ru'
    @list_link = 'http://www.sibrp.ru/members'
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
    iterate # Переход и сбор информации #time

    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_link))
    @links = [] 
    doc.css('#content-area table.views-table a').each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
    @links
  end

  def iterate
    @links[10..10].each do |link|
      puts "openinig #{link}"
      begin
        @doc = Nokogiri::HTML(open(URI.encode(link)))
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
    end
    @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @doc.css('.field-field-member-inn .field-items').text
  end

  def short_name
    raw = @doc.css('h1.title').text
  end

  def name
    raw = @doc.css('.field-field-member-title-long .field-items').text
  end

  def city
    raw = @doc.css('.field-field-member-address-legal .field-items').text

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

  def status
    raw = @doc.css('.member-note').text    
    return :w if raw == ""
    return :e if (raw.include? 'прекращено')
    return :p if (raw.include? 'приостановлено')
    '-'
  end

  def resolution_date
    raw = @doc.css('.field-field-member-certificate-date .field-items').text
  end

  def legal_address
    raw = @doc.css('.field-field-member-address-legal .field-items').text
  end

  def certificate_number
    raw = @doc.css('.field-field-member-certificate-number .field-items').text
  end

  def ogrn
    raw = @doc.css('.field-field-member-ogrn .field-items').text
  end
end








