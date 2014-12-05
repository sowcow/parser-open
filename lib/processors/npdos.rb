class Npdos
  def initialize
    @host = 'http://npdos.ru'
    @list_of_links_w = 'http://npdos.ru/register/active'
    @list_of_links_e = 'http://npdos.ru/register/excluded'
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
    collect_links @list_of_links_w, '#regactgrid' # Сбор ссылок
    collect_links @list_of_links_e, '.table_dos'
    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links list_of_links, element
    doc = Nokogiri::HTML(open(list_of_links))
    
    doc.css("#{element} a").each do |link|
      @links.push link['href']
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        @doc = Nokogiri::HTML(open(link))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        value = self.send m #for status symbols
        value = '-' if value.nil?
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
    raw = @doc.css('.postTabs_divs')[0].css('tr')[3].css('td')[1].text
    inn = raw.split('/')[0]
  end

  def short_name
    raw = @doc.css('.postTabs_divs')[0].css('tr')[1].css('td')[1].text
  end

  def name
    raw = @doc.css('.postTabs_divs')[0].css('tr')[0].css('td')[1].text
  end

  def city
    raw = @doc.css('.postTabs_divs')[0].css('tr')[4].css('td')[1].text
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
    raw = @doc.css('.postTabs_divs')[1].css('tr')[2].css('td')[1].text 
    return :w if (raw.include? 'член' or raw.include? 'Член')
    return :e if (raw.include? 'исключен' or raw.include? 'Исключен')
    raw
  end

  def resolution_date
    raw = @doc.css('.postTabs_divs')[2].css('tr')[0].css('td')[1].text 
    resolution_date = raw.split(' от ')[1]
  end

  def legal_address
    raw = @doc.css('.postTabs_divs')[0].css('tr')[4].css('td')[1].text
  end

  def certificate_number
    raw = @doc.css('.postTabs_divs')[2].css('tr')[0].css('td')[1].text 
    certificate_number = raw.split(' от ')[0]
  end

  def ogrn
    raw = @doc.css('.postTabs_divs')[0].css('tr')[3].css('td')[1].text
    ogrn = raw.split('/')[1]
  end
end
