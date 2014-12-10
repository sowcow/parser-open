class SroOsmo
  def initialize
    @host = 'http://www.sro-osmo.ru'
    @list_of_links = 'http://www.sro-osmo.ru/sroinfo/www/index.php'
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
    doc = Nokogiri::HTML(open(@list_of_links))
    raw_ids = doc.css('#FiltrForm_id > table:nth-child(3) > thead > tr > td').text
    @ids = raw_ids.split(' ').last.to_i
  end

  def iterate
    (1..@ids).each do |id|
      begin
        page = RestClient.post("http://www.sro-osmo.ru/sroinfo/www/index.php", "State=2&RegNumber=&Name=&OPF=&INN=&City=&StartDate=&SertNum=&SertStat=3&SertSum=&SertOrg=&EndDate=&Sum=&param1=&bt=#{id}&bt_old=1".postize)
      rescue => detail
        tell detail
        puts 'next link'
        next #if link is inaccessible
      end

      doc = Nokogiri::HTML(page)
      @trs = doc.css('table')[0].css('tbody tr')

      @trs.each do |tr|
        @tr = tr
        tmp = Hash.new
        @required_fields.each do |m|
          begin
            value = self.send m #for status symbols
          rescue
            value = '-'
          end
            value = value.strip if value.is_a? String
            value = '-' if value == nil
            tmp.merge! m => value
        end
        @data << tmp #@data = [tmp, {@required_fields[0] => 'value'}]
      end

    end
    @data
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    raw = @tr.css('td')[4].text
  end

  def short_name
    raw = @tr.css('td')[2].text
  end

  def name
    '-'
  end

  def city
    raw = @tr.css('td')[5].text
  end

  def status
    raw = @tr.css('td')[0].text
    if raw.include? 'Член'
      :w 
    elsif raw.include? 'Исключен'
      :e
    else
      raw
    end
  end

  def resolution_date
    raw = @tr.css('td')[6].text
  end

  def certificate_number
    raw = @tr.css('td')[7].text
  end

  def legal_address
    '-'
  end

  def ogrn
    '-'
  end
end