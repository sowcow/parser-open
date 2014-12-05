class Gsmember
  def initialize
    @host = 'http://gsmember.omkc.ru'
    @list_of_links = 'http://gsmember.omkc.ru/OrgMain'
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
    collect_links # Сбор ссылок
    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_of_links))
    
    doc.css("table tr").each do |tr|
      if !tr.css('td:nth-child(11)').text[/кандидат/i] #если кандидат, то не смотреть на страницу, там все равно оошибка
        link = tr.css('a')[0]
        if link #если ссылка есть в этом ряду
          @links.push "#{@host}#{link['href']}"
        end
      end
    end
    @links
  end

  def iterate
    @links[0..10].each do |link|
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
          value = '-' if value.nil?
          value = value.strip if value.is_a? String
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts "parsed"
    end
    @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @doc.css('table')[0].css('tr')[0].css('td')[1].text
  end

  def short_name
    raw = @doc.css('table')[0].css('tr')[4].css('td')[1].text
  end

  def name
    raw = @doc.css('table')[0].css('tr')[7].css('td')[1].text
  end

  def legal_address
    raw = @doc.css('table')[0].css('tr')[5].css('td')[1].text
  end

  def city
    raw = @doc.css('table')[0].css('tr')[5].css('td')[1].text
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
    raw = @doc.css('table')[0].css('tr')[13].css('td')[1].text
    return :w if raw[/действующий/i]
    return :e if raw[/исключен/i]
    raw
  end

  def certificate_number
    raw = @doc.css('table').last.css('tr')[1].css('td')[1].text
  end

  def resolution_date
    raw = @doc.css('table').last.css('tr')[1].css('td')[2].text
  end


  def ogrn
    raw = @doc.css('table')[0].css('tr')[1].css('td')[1].text
  end
end