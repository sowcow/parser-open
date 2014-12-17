class Apkuzsro
  def initialize
    @host = 'http://www.apkuzsro.ru'
    @list_of_links = 'http://www.apkuzsro.ru/index.php?option=com_content&view=article&id=99&Itemid=21'
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
    
    doc.css(".filterable tbody a").each do |link|
      @links.push "#{@host}#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        @doc = Nokogiri::HTML(open(link))
        @table = @doc.at_css('#maincolumn .contentpaneopen table')
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
    raw = @table.css('tr:contains("ИНН")').css('td')[1].text
  end

  def ogrn
  	raw = @table.css('tr:contains("Государственный регистрационный")').css('td')[1].text
  end

  def short_name
  	raw = @table.css('tr:contains("Сокращенное")').css('td')[1].text
  end

  def name
  	raw = @table.css('tr:contains("Полное наименование")').css('td')[1].text
  end

  def legal_address
  	raw = @table.css('tr:contains("Местонахождение")').css('td')[1].text
  end

  def city
  	raw = @table.css('tr:contains("Местонахождение")').css('td')[1].text
    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок|город|село) [А-Яа-я\- ]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def status
  	raw = @doc.text
    return :e if raw[/Исключен/i]
    :w
  end

  def certificate_number
  	raw = @doc.css('.MsoTableGrid')[-1].css('tr')[1].css('td')[1].text
  end

  def resolution_date
  	raw = @doc.css('.MsoTableGrid')[-1].css('tr')[1].css('td')[2].text
  end

end