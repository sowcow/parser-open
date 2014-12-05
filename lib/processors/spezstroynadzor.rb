class Spezstroynadzor
  def initialize
    @host = 'http://xn--80aibkhyffblhbco2d.xn--p1ai'
    @list_of_links = 'http://xn--80aibkhyffblhbco2d.xn--p1ai/reestr-chlenov-sro.html'
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
    @rows = []
    @data = []
  end

  def perform
    iterate # Переход и сбор информации

    @data
  end

  private

  def iterate

    doc = Nokogiri::HTML(open(@list_of_links))
    @rows = doc.css('tbody tr').select { |row| row.css('td')[4] } # выбираю только trs
    # в которых много td, тк есть пустые trs

    @aa = []
    @rows.each do |row|
      @row = row
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

      @aa.push legal_address
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end

    @data

  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @row.css('td')[4].text
    inn = raw[/\d+\b/]
  end

  def short_name
    raw = @row.css('td')[2].text
    raw.split('/')[1]
  end

  def name
    raw = @row.css('td')[2].text
    raw.split('/')[0]
  end

  def legal_address
    raw = @row.css('td')[5].text
  end

  def city
    raw = @row.css('td')[5].text
    test1 = raw.match /\b[А-Яа-я\- ]+[[:space:]]+(Город|Село|Станица|г,|пгт|промзона|ст-ца|д,|поселок)/i
    test2 = raw.match /\b([гсдп]\.?\s+[А-Яа-я\- ]+)\b/i

    if test1
      test1.to_s
    elsif test2
      test2.to_s
    else 
      '-'
    end
  end

  def status
    :w
  end

  def certificate_number
    raw = @row.css('td')[3].text
    raw.split('от')[0]
  end

  def resolution_date
    raw = @row.css('td')[3].text
    raw.split('от')[1].split(' ')[0].gsub ',', ''
  end


  def ogrn
    raw = @row.css('td')[4].text
    raw[/[\d]{13}/]
  end

end
