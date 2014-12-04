class Stroitel
  def initialize
    @host = 'http://stroitel.sro-stroyproekt.com'
    @list_link_w = 'http://stroitel.sro-stroyproekt.com/reestr/easytable/8-reestr-deistvuyuschih-chlenov-partnerstva'
    @list_link_e = 'http://stroitel.sro-stroyproekt.com/reestr/easytable/7-passive'
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
    @data = []
  end

  def perform
    collect_links @list_link_w, '#reestr-deistvuyuschih-chlenov-partnerstva' # Сбор ссылок
    iterate :w # собрать ссылки действующих членов

    collect_links @list_link_e, '#passive'
    iterate :e # собрать ссылки вышедших членов

    @data
  end

  private

  def collect_links url_before_n, table_selector
    doc = Nokogiri::HTML(open(@list_link_w))
    last_page_url = @host + doc.css('ul.pagination a').last['href']
    doc = Nokogiri::HTML(open(last_page_url))
    n_of_organizations = doc.css("#{table_selector} tr.et_last_row .column0 a").text.to_i
    @links = [] 
    n_of_organizations.times do |n|
      @links.push "#{url_before_n}/#{n+1}"
    end
  end

  def iterate status
    if !@links.empty?
      @links.each do |link|
        puts "openinig #{link}\n\n"
        begin
          doc = Nokogiri::HTML(open(link))
          @table = doc.css('#reestr-deistvuyuschih-chlenov-partnerstva tbody')
        rescue
          puts 'next link'
          next #if link is inaccessible
        end

        tmp = Hash.new
        tmp.merge! :status => status
        @required_fields.each do |m|
          value = self.send m
          value = value.nil? ? '-' : value.strip
          tmp.merge! m => value
        end
        @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      end
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @table.css('tr')[3].css('td')[1].text
  end

  def short_name
    '-'
  end

  def name
    raw = @table.css('tr')[2].css('td')[1].text
  end

  def city
    raw = @table.css('tr')[5].css('td')[1].text

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

  def resolution_date
    '-'
  end

  def legal_address
    raw = @table.css('tr')[5].css('td')[1].text
  end

  def certificate_number
    '-'
  end

  def ogrn
    raw = @table.css('tr')[4].css('td')[1].text
  end
end