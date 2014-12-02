class Stroysro
  def initialize
    @host = 'http://www.stroysro.ru'
    @list_link = 'http://www.stroysro.ru/chlenstvo_v_sro/reestr_chlenov.html'
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
    @data = []
  end

  def perform
    iterate # Переход и сбор информации

    @data
  end

  private

  def iterate
    doc = Nokogiri::HTML(open(@list_link))

    doc.css('table.tabwzag tbody tr').each do |row|

      @row = row 

      tmp = Hash.new
      @required_fields.each do |m|
        value = self.send(m) #for status :symbols
        value = value.strip if value.is_a? String
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
    @data
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @row.css('td')[1].inner_html
    raw.split('<br>')[0]
  end

  def short_name
    '-'
  end

  def name
    raw = @row.css('td')[0].inner_html
    raw.split('<br>')[0]
  end

  def city
    raw = @row.css('td')[2].text

    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок) [А-Яа-я\- ]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def status
    raw = @row.css('td:first-child').text
    return :e if (raw.include? 'исключен')
    :w
  end

  def resolution_date
    '-'
  end

  def legal_address
    raw = @row.css('td')[2].text
  end

  def certificate_number
    raw = @row.css('td:first-child a').text
  end

  def ogrn
    raw = @row.css('td')[1].inner_html
    raw.split('<br>')[1]
  end
end