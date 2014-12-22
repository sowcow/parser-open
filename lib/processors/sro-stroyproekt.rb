# all its dependencies:
require 'forwardable'
require 'nokogiri'
require 'open-uri'


class SroStroyproekt

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

  def perform
    data
  end

  def data
    Entry.all.map &:data
  end


  Entry = Struct.new :id do
    HOST = 'http://proektirovschik.sro-stroyproekt.com'

    def self.all
      ids.map { |id| new id }
    end

    def self.ids
      (1..last_id).map { |x| Integer x }
    end

    def self.last_id
      Integer last_page.at('table#vidy-rabot tbody tr:last td:first').text
    end

    def self.last_page
      url = "#{HOST}/reestr/easytable/17-vidy-rabot"
      last_page_url = Page[url].css('ul.pagination a').last[:href]
      Page[HOST + last_page_url]
    end


    # A, B cuz page name hardly reflects its contents and usage here
    PAGES = {
      A: "#{HOST}/reestr/easytablerecord/17-vidy-rabot/%d",
      B: "#{HOST}/reestr/easytablerecord/11-reestr-svidetelstv-o-dopuske/%d",
    }
    # not needed page: "#{HOST}/reestr/easytablerecord/15-reestr-deistvuyuschih-chlenov-partnerstva/%d"

    def initialize(*) super
      @page = PAGES.each_with_object({}) { |(name, url), pages|
        pages[name] = Page[url % id]
      }
    end
    attr_reader :page
    private :page

    def data
      FIELDS.each_with_object({}) { |field, result|
        result[field] = send field
      }
    end

    def inn
      page[:A].text_at '.sectiontablerow.column2'
    end

    def name
      page[:A].text_at '.sectiontablerow.column1'
    end

    def short_name
      nil
    end

    def city
      Extract.city legal_address
    end

    def status
      text = page[:B].text_at '.sectiontablerow.column5'
      case text
      when ''
        nil
      when /Действует/
        :w
      else
        raise [id, text].inspect
      end
    end

    def resolution_date
      Extract.date page[:B].text_at '.sectiontablerow.column4'
    end

    def legal_address
      page[:A].text_at '.sectiontablerow.column4'
    end

    def certificate_number
      Extract.cert_num page[:B].text_at '.sectiontablerow.column4'
    end

    def ogrn
      page[:A].text_at '.sectiontablerow.column3'
    end
  end

  # nice class that wraps some dependencies
  #
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

  # not reusable but ok for now
  #
  module Extract
    module_function

    def date raw
      return nil if raw == ''
      raw[/от (\d\d\.\d\d\.\d\d\d\d)/, 1] or raise [raw].inspect
    end

    def cert_num raw
      return nil if raw == ''
      raw[/^№ (.*) от/, 1] or raise [raw].inspect
    end

    def city raw
      return nil if raw == ''
      tests = []
      tests.push /\b((пос|гор|пгт|рп)\. [А-Яа-я\- ]+)\b/
      tests.push /\b([гсп]\. ?[А-Яа-я\- ]+)\b/
      tests.push /\b([д]\. ?[А-Яа-я\-][А-Яа-я\- ]+)\b/
      tests.push /\b((Р\. П\.|р\.п\.|рабочий поселок|город) [А-Яа-я\- ]+)\b/
      raw[tests.find { |x| raw =~ x }, 1] or raise
    end
  end
end
