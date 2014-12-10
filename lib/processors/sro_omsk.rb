class SroOmsk
  def initialize
    @list_of_links = 'http://www.sro-omsk.ru/reestr/'
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
    collect_links # сбор ссылок
    iterate # собрать ссылки действующих членов

    @data
  end

  private

  def collect_links
    Capybara.visit @list_of_links
    raw_ids = Capybara.first('#pagerjqxgrid > div > div:nth-child(3)').text 
    @ids = links_on_page.split(' ').last.to_i
  end

  def iterate
    @ids.times do |id|
      link = "http://www.sro-omsk.ru/reestr/view.php?id=#{id+1}"
      puts "openinig #{link}\n\n"
      begin
        @doc = Nokogiri::HTML(open(link))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        # begin
          value = self.send m
          '-' if value.nil?
          value.strip! if value.is_a? String
        # rescue
        #   value = '-'
        # end
        tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @doc.css('.table')[0].css('tr')[3].css('td')[1].text
  end

  def ogrn
    raw = @doc.css('.table')[0].css('tr')[4].css('td')[1].text
  end

  def short_name
    raw = @doc.css('h1')[0].text
  end

  def name
    raw = @doc.css('.table')[0].css('tr')[0].css('td')[1].text
  end

  def city
    raw = @doc.css('.table')[1].css('tr')[2].css('td')[1].text

    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\-]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\-]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок) [А-Яа-я\-]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    end
  end

  def legal_address
    raw = @doc.css('.table')[1].css('tr')[2].css('td')[1].text
  end

  def resolution_date
    raw = @doc.css('.table')[5].css('tr')[1].css('td')[1].text
  end

  def certificate_number
    raw = @doc.css('.table')[5].css('tr')[0].css('td')[1].text
  end

  def status
    raw = @doc.css('.table')[5].css('tr')[2].css('td')[1].text
    return :w if raw.include? 'Действует'
    return :e if raw.include? 'Выбыл'
    '-'
  end

end