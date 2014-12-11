class Spezstroynadzor
  def initialize
    @host = 'http://xn--80aibkhyffblhbco2d.xn--p1ai'
    @list_of_links_w = 'http://xn--80aibkhyffblhbco2d.xn--p1ai/reestr-chlenov-sro.html'
    @list_of_links_e = 'http://xn--80aibkhyffblhbco2d.xn--p1ai/reestr-isklyuchennyx.html'
    @required_fields = [
      :inn,
      :name,
      :short_name,
      :city,
      :resolution_date,
      :legal_address,
      :certificate_number,
      :ogrn
    ]

    @rows = []
    @data = []
  end

  def perform
    iterate :w
    iterate :e

    @data
  end

  private
  def iterate w_or_e
    if w_or_e == :w
      doc = Nokogiri::HTML(open(@list_of_links_w))
      @rows = doc.css('tbody tr').select { |row| row.css('td')[4] } # выбираю только trs
      # в которых много td, тк есть пустые trs
    elsif w_or_e == :e
      doc = Nokogiri::HTML(open(@list_of_links_e))
      @rows = doc.css('#table-reestr tbody tr')
    end

    @rows.each do |row|
      @row = row
      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send(m, w_or_e).strip.gsub(/[[:space:]]+/, ' ') #for status symbols
        rescue 
          value = '-'
        end
        tmp.merge! m => value
      end
      tmp.merge! :status => w_or_e
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end

  end


  #### Fields methods ####

  ## Required fields ##
  def inn w_or_e
    if w_or_e == :w
      raw = @row.css('td')[4].text
      raw[/\d+\b/]
    elsif w_or_e == :e
      raw = @row.css('td')[2].text
      raw[/\b[\d]{10}\b/]
    end
  end

  def short_name w_or_e
    if w_or_e == :w
      raw = @row.css('td')[2].text
      raw.split('/')[1]
    elsif w_or_e == :e
      raw = @row.css('td')[0].text
      raw.split('/')[1]
    end
  end

  def name w_or_e
    if w_or_e == :w
      raw = @row.css('td')[2].text
      raw.split('/')[0]
    elsif w_or_e == :e
      raw = @row.css('td')[0].text
      raw.split('/')[0]
    end
  end

  def legal_address w_or_e
    if w_or_e == :w
      raw = @row.css('td')[5].text
    elsif w_or_e == :e
      raw = @row.css('td')[3].text
    end
  end

  def city w_or_e
    if w_or_e == :w
      raw = @row.css('td')[5].text
    elsif w_or_e == :e
      raw = @row.css('td')[3].text
    end
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

  def certificate_number w_or_e
    if w_or_e == :w
      raw = @row.css('td')[3].text
      raw.split('от')[0]
    elsif w_or_e == :e
      raw = @row.css('td')[1].text
    end
  end

  def resolution_date w_or_e
    if w_or_e == :w
      raw = @row.css('td')[3].text
      raw.split('от')[1].split(' ')[0].gsub ',', ''
    elsif w_or_e == :e
      '-'
    end
  end

  def ogrn w_or_e
    if w_or_e == :w
      raw = @row.css('td')[4].text
      raw[/[\d]{13}/]
    elsif w_or_e == :e
      raw = @row.css('td')[2].text
      raw[/\b[\d]{13}\b/]
    end
  end

end