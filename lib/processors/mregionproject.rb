class Mregionproject
  def initialize
    @host = 'http://mregionproject.ru'
    @list_of_links = 'http://mregionproject.ru/reestr'
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
    @tables = []
    @data = []
  end

  def perform
    collect_tables # Сбор ссылок
    iterate # Переход и сбор информации

    @data
  end

  private

  def collect_tables
    doc = Nokogiri::HTML(open(@list_of_links))
    @tables = doc.css("table.member")
  end

  def iterate
    @tables.each do |table|
      @table = table

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
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @table.css('td')[0].text
    raw.split("\n")[1].split("\t")[2]
  end

  def ogrn
    raw = @table.css('td')[0].text
    raw.split("\n")[2].split(":")[1]
  end

  def short_name
    '-'
  end

  def name
    raw = @table.css('th.name').text
    raw = raw.split(/прекращено/i)[0] if raw[/прекращено/i]
    raw = raw.split(/исключен/i)[0] if raw[/исключен/i]
    raw
  end

  def legal_address
    raw = @table.css('td')[0].text
    raw.split("\n")[4].split(/факс|сайт/i)[0]
  end

  def city
    raw = @table.css('td')[0].text
    raw = raw.split("\n")[4]
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
    return :e if @table.text[/исключен|прекращено/i]
    :w
  end

  def certificate_number
    raw = @table.css('.job_header a').text
    raw[0..11]
  end

  def resolution_date
    raw = @table.at_css('.job_header').text
    raw[/\d\d\.\d\d\.[\d]{2,4}\b/]
  end

end