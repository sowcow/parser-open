class SroMrp
  def initialize
    @host = 'http://www.sro-mrp.ru'
    @list_of_links_w = 'http://www.sro-mrp.ru/reestr'
    @list_of_links_e = 'http://www.sro-mrp.ru/reestr-isklyuchennye'
    @list_of_links_p = 'http://www.sro-mrp.ru/reestr-stop'
    @required_fields = [
      :inn,
      :ogrn,
      :name,
      :short_name,
      :legal_address,
      :city,
      :certificate_number,
      :resolution_date,
      :status
    ]
    @links = []
    @data = []
  end

  def perform
    collect_links @list_of_links_w # Сбор ссылок
    collect_links @list_of_links_e
    collect_links @list_of_links_p

    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links w_e_p
    doc = Nokogiri::HTML(open(w_e_p))
    
    doc.css(".namecol a").each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        doc = Nokogiri::HTML(open(link))
        @cont = doc.css('#content')
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m #for status symbols
          value = '-' if (value.nil? or value.empty?)
          value.gsub!(/\A[[:space:]]+|[[:space:]]+\z/, '') if value.is_a? String
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts "parsed"
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @cont.at_css('p:contains("ИНН")').text
    raw.slice! 'ИНН:'
    raw
  end

  def ogrn
    raw = @cont.at_css('p:contains("ОГРН")').text
    raw.slice! ' ОГРН:'
    raw
  end

  def short_name
    '-'
  end

  def name
    raw = @cont.at_css('h1').text
  end

  def legal_address
    raw = @cont.at_css('p:contains("Адрес")').text
    raw.slice! ' Адрес:'
    raw
  end

  def city
    raw = @cont.at_css('p:contains("Адрес")').text
    raw.slice! 'Адрес:'

    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-яё\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-яё\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок|город|село) [А-Яа-яё\- ]+)\b/

    if raw[/москва/i]
      'г. Москва'
    elsif test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def status
    raw = @cont.at_css('.bigtext').text
    return :w if raw[/действует/i]
    return :e if raw[/исключен/i]
    return :p if raw[/приостановлен/i]
    '-'
  end

  def certificate_number
    raw = @cont.at_css('p:contains("Номер Свидетельства")').text
    raw.slice! 'Номер Свидетельства: '
    raw
  end

  def resolution_date
    raw = @cont.at_css('p:contains("Основание выдачи") a').text
    raw.split(' от ')[-1]
  end

end