class Sromais
  def initialize
    @host = 'http://xn--80aqkhjff.xn--p1ai'
    @list_of_links = 'http://xn--80aqkhjff.xn--p1ai/r-sro/obshchiy-reestr-mais' #excluded members are here as well
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
    collect_links
    iterate

    @data
  end

  private

  def collect_links  
    post_data = "filter-search=&limit=0&filter_order=&filter_order_Dir=&limitstart="
    page = RestClient.post(@list_of_links, post_data.postize)
    doc = Nokogiri::HTML(page)
    doc.css('.list-title a').each do |link|
      @links.push "#{@host}#{link['href']}"
    end
  end

  def iterate
    @links.each do |link|
      puts "start parsing #{link}"
      begin
        @doc = Nokogiri::HTML(open(URI.encode(link)))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      @tr = @doc.css('tbody tr:last-child')

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send(m) #for status symbols
          value = value.strip if value.is_a? String
          tmp.merge! m => value
        rescue
          tmp.merge!(m => '-') #if there was an error in data retrieval, pretend it's -
        end
      end

      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts "parsed"
    end
    @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @tr.css('td')[3].text
  end

  def short_name
    '-'
  end

  def name
    raw = @tr.css('td')[2].text
    raw.split('/')[0]
  end

  def legal_address
    raw = @tr.css('td')[5].text
  end

  def city
    raw = @tr.css('td')[5].text
    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b((р.п.|рабочий поселок|город|поселок) [А-Яа-я\- ]+)\b/
    test3 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/


    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    else
      '-'
    end
  end

  def status
    raw = @doc.css('h2+p span strong').text
    return :e if raw.include? 'прекращено'
    :w
  end

  def certificate_number
    raw = @tr.css('td')[6].text
    raw[/\b[А-Я\-0-9]{21,30}/]
  end

  def resolution_date
    raw = @tr.css('td')[6].text
    raw[/[0-3][0-9]\. ?[01][0-9]\.(20[01][0-9]|[01][0-9])/]
  end

  def ogrn
    raw = @tr.css('td')[4].text
    raw[/[\d]{13}/]
  end

end
