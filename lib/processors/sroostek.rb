class Sroostek
  def initialize
    @host = 'http://sroostek.ru'
    @list_of_links = 'http://sroostek.ru/register/'
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
    n_of_pages = doc.css('.paginator1 li')[-2].text.to_i

    (1..n_of_pages).each do |page_n|
      doc = Nokogiri::HTML(open("http://sroostek.ru/register/?page=#{page_n}"))

      doc.css("table.reg a").each do |link|
        @links.push "#{@host}#{link['href']}"
      end
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
          value.strip! if value.is_a? String
          value = '-' if (value.nil? or value.empty?)
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
    raw = @doc.css('tr').containing(/ИНН/)[0].css('td')[1].text
  end

  def ogrn
    raw = @doc.css('tr').containing(/ОГРН/)[0].css('td')[1].text
    #though seems like it's never mentioned
  end

  def short_name
    raw = @doc.css('tr').containing(/Сокращенное наименование/)[0].css('td')[1].text
  end

  def name
    raw = @doc.css('tr').containing(/Полное наименование/)[0].css('td')[1].text
  end

  def legal_address
    raw = @doc.css('tr').containing(/Юридический адрес/)[0].css('td')[1].text
  end

  def city
    raw = @doc.css('tr').containing(/Юридический адрес/)[0].css('td')[1].text
    test1 = raw.match /\b((пос|гор|пгт|рп|п\.г\.т)\. [А-Яа-яё\- ]+)\b/
    test2 = raw.match /\b((р.п.|рабочий поселок|город|село) [А-Яа-яё\- ]+)\b/
    test3 = raw.match /\b([гсдп]\. ?[А-Яа-яё\- ]+)\b/

    if raw[/москва/i]
      'г. Москва'
    elsif raw[/санкт ?\- ?петербург/i]
      'г. Санкт-Петербург'
    elsif test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def certificate_number
    '-'
  end

  def resolution_date
    '-'
  end

  def status
    :w #there are :p and :e sections, but they are empty (I suppose forever)
  end
  
end