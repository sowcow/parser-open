class Srobsk
  def initialize
    @host = 'http://www.srobsk.ru'
    @list_link = 'http://www.srobsk.ru/members/'
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
    @links = []
    list_link = @list_link

    while true
      Capybara.visit(list_link)
      puts "LIST: #{list_link}"
      Capybara.all(:xpath, '//div[@class="panel-body"]/table[@class="table table-hover table-condensed"]/tbody/tr/td/a').each do |link|
        @links << @host + link[:href]
      end

      list_link = Capybara.all(:xpath, '//span[@class="endless_page_current"]/following::a').first

      if list_link
        break
        list_link = @host + list_link[:href]
      else
        break
      end
    end
  end

  def iterate
    @links.each do |link|
      puts "Visit: #{link}"
      Capybara.visit(link)
      tmp = Hash.new
      @required_fields.each do |m|
        tmp.merge!(m => self.send(m))
      end

      @data << tmp if tmp[:status]
    end
  end

  #### Fields methods ####

  ## Required fields ##
  def inn
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"ИНН:")]/following::td').first
    slice ? slice.text : "-"
  end

  def short_name
    slice =  Capybara.all(:xpath, '//div[@class="panel-body"]/h2').first
    slice ? slice.text : "-"
  end

  def name
    slice =  Capybara.all(:xpath, '//div[@class="panel-body"]/h2').first
    slice ? slice.text : "-"
  end

  def city
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"Место нахождения юридического лица:")]/following::td').first
    address = slice ? slice.text : "-"
    /г\.[\ ]?([а-я\-\ ]+)[\.\,]+/i.match(address) ? "г. " + /г\.[\ ]?([а-я\-\ ]+)[\.\,]+/i.match(address)[1] : '-'
  end

  def status
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"Сведения о приостановлении")]/following::td').first
    info = slice ? slice.text : "-"
    info = /г\.[\ ]?(.*)\./.match(info) ? /г\.[\ ]?(.*)\./.match(info)[1] : "-"
    info == 'действует' ? :w : false
  end

  def resolution_date
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"Сведения о приостановлении")]/following::td').first
    info = slice ? slice.text : "-"
    /от[\ ]?(.*)[\ ]г\./.match(info) ? /от[\ ]?(.*)[\ ]г\./.match(info)[1] : "-"
  end

  def legal_address
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"Место нахождения юридического лица:")]/following::td').first
    slice ? slice.text : "-"
  end

  def certificate_number
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"Сведения о приостановлении")]/following::td').first
    info = slice ? slice.text : "-"
    /Свидетельство[\ ]?№[\ ]?(.*)\ от/.match(info) ? /Свидетельство[\ ]?№[\ ]?(.*)\ от/.match(info)[1] : "-"
  end

  def ogrn
    slice = Capybara.all(:xpath,'//div[@class="panel-body"]/table/tbody/tr/td[contains(text(),"ОГРН:")]/following::td').first
    slice ? slice.text : "-"
  end
end
