require 'nokogiri'
require 'open-uri'
require 'forwardable'


class Sroostek
  HOST = 'http://sroostek.ru'
  LINKS_PAGE =  'http://sroostek.ru/register/'

  FIELDS = %i[
    inn
    name
    short_name
    city
    status
    resolution_date
    legal_address
    certificate_number
    ogrn
  ]

  def HOST.+(other)  URI.join(self, other).to_s  end

  def initialize
    @links = []
    @data = []
  end

  def perform
    data
  end

  def data
    Entry.all.map &:data
  end


  Page = Struct.new :url do
    def body
      @body ||= Nokogiri.HTML open url
    end
    extend Forwardable
    delegate %i[ at css text ] => :body
    def text_at selector
      at(selector).text
    end
  end


  Entry = Struct.new :url do

    def self.all
      urls.map { |x| new x }
    end

    def self.urls
      pages.flat_map { |page_url|
        Page[page_url].at('.reg').css('a')
        .map { |a| HOST + a[:href] }
        # host had worked out here so ok
      }
    end

    def self.pages
      (1..max_page).map { |n| PAGE_URL[n] }
    end
    PAGE_URL = -> n { HOST + "/register/?page=#{n}" }
    
    def self.max_page
      page = Nokogiri.HTML open LINKS_PAGE
      paginator = page.at '.paginator1 > ul'
      pages = paginator.css('li').map { |x|
        x.text.to_i
      }.reject { |x| x == 0 } # минус мусор

      pages.last
    end

    def data
      FIELDS.each_with_object({}) { |field, data|
        data[field] = send field
      }
    end
  
    def page
      @page ||= Page[url]
    end

    def section_3
      @s3 ||= page.at '#section3'
    end
    def section_3_text
      @s3text ||= section_3.text.
        gsub /[[:space:]]+/, ' '
    end
  
  
    def inn
      selector = ':nth-child(6) .last'
      page.at(selector).text.strip
    end

    def name
      selector = '.first.grey td:nth-child(2)'
      page.at(selector).text.strip
    end

    def short_name
      selector = 'tr:nth-child(3) .last'
      page.at(selector).text.strip
    end

    def city
      extract_city legal_address
    end
  
    def legal_address
      selector = ':nth-child(8) .last'
      page.at(selector).text.strip
    end

    # было 2-3 исключения, где приостановлено + после возобновлено, и надо сравнивать даты,
    # но т.к. скорость была обозначена как приоритет, то ок
    def status
      case section_3_text
      when /Свидетельство приостановлено/i
        :p
      else
        :w
      end
    end

    def ogrn
      section_3_text[/огрн:#{FIRST_NUMBERS}/i, 1]
    end
    FIRST_NUMBERS = /[^\d]*?(\d+)/


    ###
    #
    # далее идут методы посложнее......
    #
    ###


    # у некоторых там дата приостановления, у некоторых дата возобновления
    NO_DATE = %w[
      http://sroostek.ru/register/ooo_regionteplomontazh/
      http://sroostek.ru/register/ooo_nord-al/
      http://sroostek.ru/register/ooo_ekotehnolodzhi/
      http://sroostek.ru/register/ooo_kapitalstroy/
      http://sroostek.ru/register/ooo_evroaziya/
      http://sroostek.ru/register/ooo_gk_energocentr/
    ]
    def resolution_date
      return nil if NO_DATE.include? url
  
      основание_выдачи =
        section_3_text[
          /Основание.выдачи.Свидетельства:.(.*)\./i ,1
        ]

      date = основание_выдачи[/[\d\s]от(.*?[\d\s])г/, 1].strip

      return date if date =~ /^\d\d\.\d\d\.\d\d\d\d$/
      reformat_date date
    end

    # «05» апреля 2012 г  ->  05.04.2012
    #
    def reformat_date str
      str = '«07» ноября 2013' if str == '«07» ноября2 013' # ...
  
      parts = str.scan /\p{Word}+/

      day = parts[0][/\d+/].to_i

      month = MONTHS[parts[1]]
      year = parts[2].to_i
      '%02d.%02d.%d' % [day, month, year]
    end
    MONTHS = {
      'января' => 1,
      'февраля' => 2,
      'марта' => 3,
      'апреля' => 4,
      'мая' => 5,
      'июня' => 6,
      'июля' => 7,
      'августа' => 8,
      'сентября' => 9,
      'октября' => 10,
      'ноября' => 11,
      'декабря' => 12,
      'Декабря' => 12, #... or unicode downcase for all?
    }
  
  
    NO_SERT = %w[
      http://sroostek.ru/register/ooo_vliko_stroy/
      http://sroostek.ru/register/ooo_uralskiy_zavod_drobilno-sortirovochnogo_oborudovaniya/
      http://sroostek.ru/register/ooo_smu_sm/
      http://sroostek.ru/register/ooo_leningradskiy_proektnyy_institut_na_rechnom_transporte/
    ]
    def certificate_number
      return nil if NO_SERT.include? url
  
      # там лишний пробел
      return '0222.00-2011-7703693591-С-238' if url == 'http://sroostek.ru/register/ooo_lamayer_internacional_rus/'
  
      # куски текста
      entries = section_3.children.map &:text
  
      # подходящий кусок
      this = entries.select { |x| x =~ CERT_NUM }
      # слишком большой с мусором? XXX
  
  
      this = this.first
  
      # избавиться от мусора вначале
      this = this[CERT_NUM, 1]
  
      # с первого числа или буквы до конца
      this = this[/[[:alnum:]].*/]
      
      # взять всё до пробела
      this = this.split(' ', 2).first
  
      this = this.sub /(?<=-238).*/,''
      this
    end
    CERT_NUM = /Номер.свидетельства(.*)/i
  
  
    def extract_city raw

      test1 = raw.match /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
      test2 = raw.match /\b([гсп]\. ?[А-Яа-я\- ]+)\b/
      test2d = raw.match /\b([д]\. ?[А-Яа-я\-][А-Яа-я\- ]+)\b/
      test3 = raw.match /\b((Р\. П\.|р\.п\.|рабочий поселок|город) [А-Яа-я\- ]+)\b/
  
      test4 = []
      test4.push raw.match /\b((Г\.|г\.)[[:space:]]+[А-Яа-я\- ]+)\b/ # double space...
      test4.push raw.match /\b((поселок) [А-Яа-я\- ]+)\b/
      test4.push raw.match /\b([А-Яа-я\- ]+ (г|ст-ца|поселок|рп))\.?,/  # "Якутск г" - ок?
      test4.push raw.match /\b((дер\.|деревня|Село|село|пгт|мгт|ст.|ст-ца) [А-Яа-я\- ]+)\b/
      test4.push raw.match /\b((город-курорт|сельское поселение) [А-Яа-я\- ]+)\b/
      test4.push raw.match /\b(г\.[А-Яёа-я\- ]+)\b/
  

      # последний тест
      known = {

        /^184367,/ => 'пгт Кильдинстрой',
        /^163530,/ => 'пос. Талаги',
        /^129344,/ => 'г. Москва',
        /^344016,/ => 'Ростов-на-Дону',
        /^603000,/ => 'Н. Новгород',
        /^167000,/ => 'Сыктывкар',
        /Санкт-Петербург/ => 'г. Санкт-Петербург',
        /603024, Н. Новгород/ => 'г. Н. Новгород',
        /111141, (РФ, )?Москва/ => 'г. Москва',

        /, Великий Новгород,/ => 'г. Великий Новгород',
        /Хабаровский край, ул. Волочаевская, д.8/ => 'г. Хабаровск',
        / Сахарово, пгт/ => 'пгт. Сахарово, пгт',
        /Тюменская область, ул. Энергетиков, дом 167/ => 'г. Тюмень',
        /Нижний Новгород/ => 'г. Нижний Новгород',
        /302038 Орловская область, Орловский район, ул. Раздольная, дом 91/ =>
         'г. Орёл',
        /Ставропольский край, Шпаковский район, Бройлерная промышленная зона, 9/=>
         nil, # XXX
         /390023, г., Рязань/ => 'г. Рязань', 
         /, р\.п\., Средняя Ахтуба,/ => 'р.п. Средняя Ахтубаг',
      }
  
  
      # лень рефакторить это...
      if test1
        test1[1]
      elsif test2
        test2[1]
      elsif test2d
        test2d[1]
      elsif test3
        test3[1]
      elsif test4.any? { |x| x }
        test4.reject { |x| not x }.first[1]
      else
        if got = known.find { |x,_| x =~ raw }
          return got[1]
        end
      end
    end
  
  end
end
