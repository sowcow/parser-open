class SroOpus
  def initialize
    @host = 'http://www.sro-opus.ru'
    @list_of_links = 'http://www.sro-opus.ru/?page=14'
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
    collect_links # Сбор ссылок
    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_of_links))
    
    doc.css("table[bgcolor='#CCCCCC'] tr:not(:first-child) td:nth-child(2) a").each do |link|
      @links.push "#{@host}#{link['href']}"
    end
  end

  def iterate
    @links[0.each do |link|
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
    raw = @doc.css('table')[0].at_css('tr:contains("ИНН")').css('td')[1].text
  end

  def ogrn
    raw = @doc.css('table')[0].at_css('tr:contains("ОГРН")').css('td')[1].text
  end

  def short_name
    raw = @doc.css('table')[0].at_css('tr:contains("сокращенное")').css('td')[1].text
  end

  def name
    raw = @doc.css('table')[0].at_css('tr:contains("полное")').css('td')[1].text
  end

  def legal_address
    raw = @doc.css('table')[0].at_css('tr:contains("адрес")').css('td')[1].text
  end

  def city
    raw = @doc.css('table')[0].at_css('tr:contains("адрес")').css('td')[1].text
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
    raw = @doc.css('table')[0].at_css('tr:contains("приостановлении")').css('td')[1].text
    :w #они там все воркинг, пока не могу предсказать как выглядит не воркинг
  end

  def certificate_number
    raw = @doc.css('table')[1].at_css('tr:last-child').css('td')[0].text
  end

  def resolution_date
    raw = @doc.css('table')[1].at_css('tr:last-child').css('td')[1].text
  end

end
