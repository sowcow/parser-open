class OspAmur
  def initialize
    @host = 'http://www.osp-amur.ru'
    @list_of_links = 'http://www.osp-amur.ru/mainreg.html'
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
    
    doc.css("tbody tr a").each do |link|
      @links.push link['href']
    end
  end

  def iterate
    @links[-50..-1].each do |link|
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
    raw = @doc.css('#tabs-1').css('tr:contains("ИНН:")').at_css('td').text
  end

  def ogrn
    raw = @doc.css('#tabs-1').css('tr:contains("ОГРН / ОГРНИП:")').at_css('td').text
  end

  def short_name
    raw = @doc.at_css('#MainContent_lbl_namesocr')
    raw.children.to_s.encode('utf-8').split('<br><br>')[0]
  end

  def name
    raw = @doc.at_css('#MainContent_lbl_namesocr')
    raw.children.to_s.encode('utf-8').split('<br><br>')[1]
  end

  def legal_address
    raw = @doc.css('#tabs-1').css('tr:contains("Адрес места нахождения:")').at_css('td').text
  end

  def city
    raw = @doc.css('#tabs-1').css('tr:contains("Адрес места нахождения:")').at_css('td').text
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
    raw = @doc.css('#tabs-1').css('tr:contains("Членство в СРО:")').at_css('td').text
    return :w if raw[/состоит/i]
    return :e if raw[/прекращено/i]
    :w
  end

  def certificate_number
    raw = @doc.css('#tabs-2 tbody').css('tr')[0].css('td')[1].text
  end

  def resolution_date
    raw = @doc.css('#tabs-2 tbody').css('tr')[0].css('td')[3].text
  end

end
