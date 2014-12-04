class Sroglavstroy
  def initialize
    @host = 'http://www.sroglavstroy.ru'
    @list_of_links_w = 'http://www.sroglavstroy.ru/reestr1/index.php'
    @list_of_links_e = 'http://stroitel.sro-stroyproekt.com/reestr/easytable/7-passive' #time
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
    @links = []
  end

  def perform
    collect_links @list_of_links_w # собрать ссылки действующих членов
    collect_links @list_of_links_e # собрать ссылки вышедших членов
    iterate 

    @data
  end

  private

  def collect_links list_of_links
    next_src = list_of_links
    # while true
    2.times do
      doc = Nokogiri::HTML(open(next_src))
      doc.css('.news-list tbody tr:not(:first-child)').each do |tr|
        @links.push "#{@host}#{tr.css('a')[0]['href']}"
      end

      next_page = doc.at('.news-list .text:last-child a:contains("След.")')
      break if next_page.nil?
      next_src = @host + next_page['href']
    end

  end

  def tell detail #prettify error messages
    puts "\n\n\n"
    puts "#{"_"*60}\n#{detail.message}\n#{"_"*60}\n#{detail.backtrace.select{ |i| i.include?'sroglavstroy' }.join("\n")}\n#{"="*50}\n\n\n"
  end

  def iterate
    if !@links.empty?
      @links.each do |link|
        puts "start parsing #{link}"
        begin
          doc = Nokogiri::HTML(open(link))
          @table = doc.css('.table1')
        rescue
          puts 'next link'
          next #if link is inaccessible
        end

        tmp = Hash.new
        @required_fields.each do |m|
          retries = 0
          begin
            value = self.send m
          rescue => detail
            retries += 1 #иногда не грузится несколько раз страница. попробовать три раза и перестать.
            m == :name and retries < 4 ? retry : value = '-'
          end
          if value.is_a? String
            value = value.nil? ? '-' : value.gsub(/[[:space:]]+\z|\A[[:space:]]+/, '') #not strip because of strange UTF characters
          end
          tmp.merge! m => value
        end
        @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
        puts "parsed\n"
      end
    end
    p @data
  end

  #___ Fields methods ___#

  #_ Required fields _#
  def inn
    raw = @table.at('tr td:contains("ИНН")+td p').text
  end

  def short_name
    raw = @table.at('tr td:contains("Сокращенное наименование ЮЛ")+td p').text
  end

  def name
    raw = @table.at('tr td:contains("Полное наименование ЮЛ")+td p').text
  end

  def city
    raw = @table.at('tr td:contains("Юридический")+td p').text

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

  def status
    raw = @table.at('tr td:contains("Статус")+td p').text
    return :w if raw.include? 'Соответствует'
    return :e if raw.include? 'Не соответствует'
    '-'
  end

  def resolution_date
    raw = @table.at('tr td:contains("Дата выдачи")+td p').text
  end

  def legal_address
    raw = @table.at('tr td:contains("Юридический")+td p').text
  end

  def certificate_number
    raw = @table.at('tr td:contains("Номер свидетельства")+td p').text
  end

  def ogrn
    raw = @table.at('tr td:contains("Основной государственный регистрационный номер ОГРН")+td p').text
  end
end


Sroglavstroy.new.perform



#ждать пока он ответит про статус и потом проверить поля