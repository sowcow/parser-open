class Objedineniyestroiteley
  def initialize
  	@host = 'http://xn--90agcbaaaubbnwubij7artd8m.xn--p1ai'
    @table_start = 'http://xn--90agcbaaaubbnwubij7artd8m.xn--p1ai/index.php/reestr-chlenov-sro'
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

    doc = Nokogiri::HTML(open(@table_start))

    while !doc.css('a').containing(/следующая страница/i)[0].nil?
      next_href = doc.css('a').containing(/следующая страница/i)[0]['href']
      next_href = next_href.split('рф')[1] if next_href[/http/] 
      next_link = @host + next_href
      @links.push next_link
      doc = Nokogiri::HTML(open(next_link))
    end

  end

  def iterate    
    @links.each do |link|
      doc = Nokogiri::HTML(open(link))
      trs = doc.css('tbody')[-1].css('tr')
      trs.each do |tr|
      	@tr = tr
        tmp = Hash.new
        @required_fields.each do |m|
          begin
            value = self.send m #for status symbols
            value = '-' if (value.nil? or value.empty?)
            value.strip! if value.is_a? String
          rescue
            value = '-'
          end
          tmp.merge! m => value
        end
        @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      end
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @tr.css('td')[5].text
  end

  def ogrn
    raw = @tr.css('td')[7].text
  end

  def short_name
    raw = @tr.css('td')[3].text
  end

  def name
    raw = @tr.css('td')[2].text
  end

  def legal_address
    raw = @tr.css('td')[8].text
  end

  def city
    raw = @tr.css('td')[8].text
    test1 = raw.match /\b((пос|гор|пгт|рп|п\.г\.т)\. [А-Яа-яё\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-яё\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок|город|село) [А-Яа-яё\- ]+)\b/

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

  def status
    '-' #много инфы, но именно о том состоит ли - ничего нет
  end

  def certificate_number
    raw = @tr.css('td')[18].text
    raw[/№\d+/]
  end

  def resolution_date
    '-'
  end

end