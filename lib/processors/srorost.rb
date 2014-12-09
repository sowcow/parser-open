class Srorost
  def initialize
    @host = 'http://srorost.ru'
    @list_of_links = 'http://srorost.ru/reestr'
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
    collect_links # сбор ссылок
    iterate # собрать ссылки действующих членов

    p @data
  end

  private

  def collect_links
    @links = [] 
    Capybara.visit @list_of_links

    n = 10 # 10 ссылок одинаковы => прекратить листать. нельзя прекратить листать при первом повторе тк они повторяются иногда.
    finished = false
    while !finished
      links_on_page = Capybara.all '#text .sreg_tb tbody tr a'

      links_on_page.each do |link| 
        link = "#{@list_of_links}/#{link['href']}"
        if @links.include? link
          n == 0 ? finished = true : n -= 1
        else 
          @links.push link
        end
      end

      next_button = Capybara.first('#sreg_nav input[name="next"]')
      next_button.click
    end
  end

  def iterate
    @links[0..5].each do |link|
      puts "openinig #{link}\n\n"
      begin
        doc = Nokogiri::HTML(open(link))
        @doc= doc.css('#text')
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m
          value = value.nil? ? '-' : value.strip
        rescue
          value = '-'
        end
        tmp.merge! m => value
      end
      tmp.merge! status: :w
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @doc.css('.sreg_tb')[1].css('tr')[4].css('td')[1].text
  end

  def ogrn
    raw = @doc.css('.sreg_tb')[1].css('tr')[3].css('td')[1].text
  end

  def short_name
    raw = @doc.css('.sreg_tb')[1].css('tr')[2].css('td')[1].text
  end

  def name
    raw = @doc.css('.sreg_tb')[1].css('tr')[1].css('td')[1].text
  end

  def city
    raw = @doc.css('.sreg_tb')[2].css('tr')[0].css('td')[1].text

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

  def legal_address
    raw = @doc.css('.sreg_tb')[2].css('tr')[0].css('td')[1].text
  end

  def resolution_date
    raw = @doc.css('.sreg_tb')[7].css('tr')[1].css('td')[1].text
  end

  def certificate_number
    raw = @doc.css('.sreg_tb')[7].css('tr')[0].css('td')[1].text
  end

end