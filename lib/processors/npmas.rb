class Npmas
  def initialize
    @host = 'http://www.npmas.ru'
    @list_link = 'http://www.npmas.ru/members.php'
    @data_link_template = ''
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
    collect_links # Сбор ссылок
    iterate # Переход и сбор информации #time
    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_link))
    pages = [@list_link] 
    doc.css('table+p a').each do |link|
      pages.push "#{@host}/#{link['href']}"
    end

    @links = [] 
    pages.each do |page|
      doc = Nokogiri::HTML(open(page))
      doc.css('table.members a').each do |link|
        @links.push "#{@host}/#{link['href']}"
      end
    end
  end

  def iterate
    @links.each do |link|
      puts "openinig #{link}\n"
      begin
        Capybara.visit(link)
      rescue => detail
        tell detail
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
          value = self.send(m) #for status symbols
          value = value.strip if value.is_a? String
          tmp.merge! m => value
      end
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
    end
    @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = Capybara.first('td strong', text: 'ИНН').first(:xpath, '../..').first('td:nth-child(2)').text
  end

  def short_name
    '-'
  end

  def name
    raw = Capybara.first('td strong', text: 'Название').first(:xpath, '../..').first('td:nth-child(2)').text
  end

  def city
    raw = Capybara.first('td strong', text: 'Место нахождения').first(:xpath, '../..').first('td:nth-child(2)').text

    test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
    test2 = raw.match /\b([гсдп]\. ?[А-Яа-я\- ]+)\b/
    test3 = raw.match /\b((р.п.|рабочий поселок) [А-Яа-я\- ]+)\b/

    if test1
      test1[1]  
    elsif test2
      test2[1]
    elsif test3
      test3[1]
    else
      Capybara.first('td strong', text: 'Регион').first(:xpath, '../..').first('td:nth-child(2)').text
    end
  end

  def status
    raw = Capybara.first('td strong', text: 'Статус допуска').first(:xpath, '../..').first('td:nth-child(2)').text
    if raw.include? 'действующий'
      :w 
    elsif raw.include? 'исключена'
      :e
    else
      '-'
    end
  end

  def resolution_date
    raw = Capybara.first('td strong', text: 'Дата регистрации в реестре в соответствии с протоколом').first(:xpath, '../..').first('td:nth-child(2)').text
    resolution_date = raw.include?(' от ') ? raw.split(' от ')[1] : raw
  end

  def legal_address
    raw = Capybara.first('td strong', text: 'Место нахождения').first(:xpath, '../..').first('td:nth-child(2)').text
  end

  def certificate_number
    raw = Capybara.first('td strong', text: 'Номер свидетельства').first(:xpath, '../..').first('td:nth-child(2)').text
  end

  def ogrn
    raw = Capybara.first('td strong', text: 'ОГРН').first(:xpath, '../..').first('td:nth-child(2)').text
  end
end



