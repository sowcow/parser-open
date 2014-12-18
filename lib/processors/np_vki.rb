class NpVki
  def initialize
    @host = 'http://xn----dtbshmm.xn--p1ai'
    @list_of_links = 'http://xn----dtbshmm.xn--p1ai/reestr-tablica.html'
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
    iterate # Переход и сбор информации

    @data
  end

  private

  def iterate
    doc = Nokogiri::HTML(open(@list_of_links))
    trs = doc.css('tr:not(:first-child)').select { |tr| tr.text.strip.length > 0 } #strip so that empty rows don't get recorded
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

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @tr.css('td')[3].text
  end

  def ogrn
    '-'
  end

  def short_name
    '-'
  end

  def name
    raw = @tr.css('td')[1].text
  end

  def legal_address
    raw = @tr.css('td')[2].css('p')[0].text
  end

  def city
    raw = @tr.css('td')[2].css('p')[0].text
    test1 = raw.match /\b((пос|гор|пгт|рп|п\.г\.т)\. [А-Яа-яё\- ]+)\b/
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
    raw = @tr.css('td')[4].text
    raw.gsub! /[[:space:]]/, ''
    return :w if raw == 'действующий'
    return :e if raw == 'недействующий'
  end

  def certificate_number
    '-'
  end

  def resolution_date
    '-'
  end

end
