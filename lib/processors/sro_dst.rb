class SroDst
  def initialize
    @host = 'http://sro-dst.ru'
    @list_link_w = 'http://sro-dst.ru/reestr'
    @list_link_e = 'http://sro-dst.ru/reestrout/'
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
    collect_links @list_link_w # Сбор ссылок
    iterate :w # собрать ссылки действующих членов

    collect_links @list_link_e
    iterate :e # собрать ссылки вышедших членов

    @data
  end

  private

  def collect_links url_for_w_or_e_status
    @links = [] 
    Capybara.visit url_for_w_or_e_status
    popup = Capybara.first('#fancybox-close')
    popup.click if popup

    finished = false
    while !finished
      links_on_page = Capybara.all 'div.news-list tbody td:first-child a'

      links_on_page.each do |link| 
        @links.push "#{@host}#{link['href']}" 
      end
      finished = true if Capybara.all('#center_block > div.news-list tr').length < 21
      next_button = Capybara.first('#mb_nav input[name="next"]')
      next_button ? next_button.click : finished = true
    end
  end

  def iterate status
    if !@links.empty?
      @links.each do |link|
        puts "openinig #{link}\n\n"
        begin
          doc = Nokogiri::HTML(open(link))
          @table = doc.css('.table-chlen-sro tbody')
        rescue
          puts 'next link'
          next #if link is inaccessible
        end

        tmp = Hash.new
        tmp.merge! :status => status
        @required_fields.each do |m|
          begin
            value = self.send m
            value = value.nil? ? '-' : value.strip
          rescue
            value = '-'
          end
          tmp.merge! m => value
        end
        @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      end
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @table.css('tr')[8].css('td')[1].text
  end

  def short_name
    raw = @table.css('tr')[6].css('td')[1].text
  end

  def name
    raw = @table.css('tr')[5].css('td')[1].text
  end

  def city
    raw = @table.css('tr')[11].css('td')[1].text

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
    raw = @table.css('td:contains("Дата выдачи")')[1].css('+td').text
  end

  def legal_address
    raw = @table.css('tr')[11].css('td')[1].text
  end

  def certificate_number
    raw = @table.css('td:contains("Номер свидетельства")')[0].css('+td').text
  end

  def ogrn
    raw = @table.css('tr:nth-child(8) > td:nth-child(2)').text
  end
end
