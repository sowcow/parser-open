class Npeas
  def initialize
    @host = 'http://npeas.ru'
    @list_of_links_w = 'http://npeas.ru/?page_id=2372'
    @list_of_links_e = 'http://npeas.ru/?page_id=5832'
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

    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links w_or_e
    doc = Nokogiri::HTML(open(w_or_e))
    
    doc.css('#tbl a').each do |link|
      @links.push "#{@host}#{link['href']}"
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
        begin
          value = self.send m #for status symbols
          value = '-' if (value.nil? or value.empty?)
          value = value.strip if value.is_a? String
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
    raw = @doc.at_css('tr:contains("ИНН:")').css('td')[1].text
  end

  def ogrn
    raw = @doc.at_css('tr:contains("Основной государственный")').css('td')[1].text
    raw
  end

  def short_name
    raw = @doc.at_css('tr:contains("Полное, сокращенное наименование:")').css('td')[1].text
    raw.split(',')[1]
  end

  def name
    raw = @doc.at_css('tr:contains("Полное, сокращенное наименование:")').css('td')[1].text
    raw.split(',')[0]
  end

  def legal_address
    raw = @doc.css('tr:contains("Место нахождения:")').css('td')[1].text
  end

  def city
    raw = @doc.css('tr:contains("Место нахождения:")').css('td')[1].text
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
    raw = @doc.css('table').text
    return :e if raw[/Основание прекращение членства:/i]
    return :p if raw.include? 'ПРИОСТАНОВЛЕНО'
    :w
  end

  def certificate_number
    raw = @doc.at_css('.MsoNormal:contains("Свидетельство")').text
    raw[/[\d\-\.A-Z]{27,31}/]
  end

  def resolution_date
    raw = @doc.at_css('.MsoNormal:contains("Дата выдачи свидетельства:")').text
    raw[/[\d\.]{8,10}/]
  end

end