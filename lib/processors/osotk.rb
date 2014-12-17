class Osotk
  def initialize
    @host = 'http://www.osotk.ru'
    @list_of_links = 'http://www.osotk.ru/subpage_p_6.html'
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
    
    doc.css("#contentip li a").each do |link|
      @links.push "#{@host}#{link['href']}" 
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        doc = Nokogiri::HTML(open(link))
        @div = doc.at_css('#contentip')
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
    raw = @div.at_css('p:contains("ИНН")').text
    raw.slice! 'ИНН'
    raw
  end

  def ogrn
    raw = @div.at_css('p:contains("ОГРН")').text
    raw.slice! 'ОГРН'
    raw.split('от')[0]
  end

  def short_name
    raw = @div.at_css('p:contains("Сокращенное наименование ЮЛ:")').text
    raw.slice! 'Сокращенное наименование ЮЛ:'
    raw
  end

  def name
    raw = @div.at_css('p:contains("Полное наименование ЮЛ:")').text
    raw.slice! 'Полное наименование ЮЛ:'
    raw
  end

  def legal_address
    raw = @div.at_css('p:contains("Адрес юридический:")').text
    raw.slice! 'Адрес юридический:'
    raw
  end

  def city
    raw = @div.at_css('p:contains("Адрес юридический:")').text
    raw.slice! 'Адрес юридический:'
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
    :w
  end

  def certificate_number
    raw = @div.css('a').text
    raw[/[\d\-\.A-ZА-Я]{27,33}/]
  end

  def resolution_date
    raw = @div.css('a').text
    raw[/[0-3]?[0-9]\.[0-1]?[0-9]\.[\d]{2,4}/]
  end

end