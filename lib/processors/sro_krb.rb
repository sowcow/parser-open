class SroKrb
  def initialize
    @host = 'http://sro-krb.ru'
    @list_of_links = 'http://sro-krb.ru/perechen_chlenov_np'
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
    @links_w = []
    @links_e = []
    @data = []
  end

  def perform
    collect_links # Сбор ссылок
    iterate :w, @links_w # Переход и сбор информации
    iterate :e, @links_e
    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_of_links))
    links = doc.css('.content p')
    links = links.select { |link| link.text[/\b\d+\. /] and link.css('a')[0] } 

    firsts = 0 #потому что ссылки в w и e вообще не оформлены в какие-то контейнеры
    #firsts считает сколько ей встретилось на пути ссылок с текстом '1. '
    links.each do |link|
      firsts += 1 if link.text[/\b1\. /]
      @links_w.push(@host + link.css('a')[0]['href']) if firsts == 1
      break if firsts == 2
    end

    firsts = 0
    links.each do |link|
      firsts += 1 if link.text[/\b1\. /]
      @links_e.push(@host + link.css('a')[0]['href']) if firsts == 2
      break if firsts == 3
    end

    #потом еще возможно добавить @links_p
  end

  def iterate w_or_e, links
    links.each do |link|
      puts "start_parsing #{link}"
      begin
        @doc = Nokogiri::HTML(open(link))
      rescue
        puts 'next link'
        next #if link is inaccessible
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          value = self.send m, w_or_e #for status symbols
        rescue
          value = '-'
        end
        value = '-' if value == nil
        value = value.gsub(/[[:space:]]+\z|\A[[:space:]]+/, '') if value.is_a? String
        tmp.merge! m => value
      end
      tmp.merge! status: w_or_e
      @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      puts 'parsed'
    end
    @data
  end

  #### Fields methods ####

  # ## Required fields ##
  def inn w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[1].css('td')[1].text
    elsif w_or_e == :e
      raw = @doc.css('.content tbody').css('tr')[0].css('td')[1].text
    end
  end

  def ogrn w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[2].css('td')[1].text
    elsif w_or_e == :e
      raw = @doc.css('.content tbody').css('tr')[1].css('td')[1].text
    end
  end

  def short_name w_or_e
    if w_or_e == :w
      raw = @doc.css('h1.pagename').text
    elsif w_or_e == :e
      raw = @doc.css('h1.pagename').text
    end
  end

  def name w_or_e
    if w_or_e == :w
      raw = @doc.css('.content > p:nth-child(2)').text
    elsif w_or_e == :e
      raw = @doc.css('.content > p:nth-child(3)').text
    end
  end

  def city w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[8].css('td')[1].text
    elsif w_or_e == :e
      raw = @doc.css('.content tbody').css('tr')[9].css('td')[1].text
    end
      

    return 'Москва' if raw.include? 'Москва'
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
      '-'
    end
  end

  def legal_address w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[8].css('td')[1].text
    elsif w_or_e == :e
      raw = @doc.css('.content tbody').css('tr')[9].css('td')[1].text
    end
  end

  def resolution_date w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[16].css('td')[1].text
      raw.split('от')[1]
    elsif w_or_e == :e
      '-'
    end
  end

  def certificate_number w_or_e
    if w_or_e == :w
      raw = @doc.css('.content tbody').css('tr')[16].css('td')[1].text
      raw.split('от')[0]
    elsif w_or_e == :e
      '-'
    end
  end

end