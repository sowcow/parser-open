class Odinso_stroy
  def initialize
    @host = 'http://odinsro-stroy.ru'
    @list_link = 'http://odinsro-stroy.ru/reestr/'
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
    iterate # Переход и сбор информации
    @data
  end

  private

  def collect_links
    doc = Nokogiri::HTML(open(@list_link))
    @links = [] 
    doc.css('div#maincontent li:not(:first-child) a').each do |link|
      @links.push "#{@host}/#{link['href']}"
    end
    @links
  end

  def iterate
    @links.each do |link|
      puts "openinig #{link}"
      begin
        @doc = Nokogiri::HTML(open(URI.encode(link)))
      rescue
        puts 'next link'
        next
      end

      tmp = Hash.new
      @required_fields.each do |m|
        begin
          tmp.merge!(m => self.send(m))
        rescue
          tmp.merge!(m => '-')
        end
      end

      @data << tmp if tmp[:status] #@data = [tmp, {@required_fields[0] => 'value'}]
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    slice = @doc.css('li:not(:first-child) td.t5').text.split('/')
    slice[0].strip
  end

  def short_name
    slice = @doc.css('li:not(:first-child) td.t3').text.split('/ ')
    slice[1] ? slice[1].strip : '-'
  end

  def name
    slice = @doc.css('li:not(:first-child) td.t3').text
    slice.split('/ ')[0].strip
  end

  def city
    slice = @doc.css('li:not(:first-child) td.t4').text

    if slice.include? 'г. '
      slice = 'г. ' + slice.split('г. ')[1].split(' ')[0]
    elsif slice.include? 'п. '
      slice = 'п. ' + slice.split('п. ')[1].split(' ')[0]
    elsif slice.include? ' г,'
      slice = 'г. ' + slice.split(' г,')[0].strip.split(' ').last
    elsif slice.include? ' п,'
      slice = 'п. ' + slice.split(' п,')[0].strip.split(' ').last
    else
      slice = '-'
    end
    slice.slice!(',') if slice.include? ','
    slice.strip
  end

  def status
    slice = @doc.css('li:not(:first-child) td.t7').text    
    if slice.include? '----------'
      :w
    elsif slice.include? 'Исключен' or slice.include? 'Выбыл'
      false
    else
      '-'
    end
  end

  def resolution_date
    slice = @doc.css('tr:nth-child(8) span.font5').text
    slice = @doc.css('tr:nth-child(8) p:first-child').text if slice == ""
    slice.split(' от ')[1].strip
  end

  def legal_address
    slice = @doc.css('li:not(:first-child) td.t4').text
  end

  def certificate_number
    slice = @doc.css('tr:nth-child(8) span.font5').text
    if slice.include? 'свидетельство'
      slice.split('свидетельство')[1].split('от')[0].strip 
    else
      slice.split('от')[0].strip
    end
  end

  def ogrn
    slice = @doc.css('li:not(:first-child) td.t5').text.split('/')
    slice[1].strip
  end
end

