# Class for export data via different ways
class Exporter

  class << self
    attr_accessor :statuses
  end

  @statuses = {
        :w => "Действует",
        :p => "Приостановлен",
        :c => "Отозван",
        :e => "Исключен"
  }

  def initialize(type = :mysql, data = [], source)
    @source = source
    send(type, data)
  end

  private

  # def mysql(data)
  #   # Simple and plain export, for starters
  #   data.each do |row|
  #     row[:status] = Exporter.statuses[row[:status]]
  #     @source.companies.find_or_create_by(inn: row[:inn]).update_attributes!(row)
  #   end
  # end

  def csv(data)
    filename = "data/#{@source[:registry_number]}.csv"
    CSV.open(filename, "wb") do |csv|
      csv << [
          "ИНН",
          "Полное наименование",
          "Краткое наименование",
          "Город",
          "Статус в СРО",
          "Допуск выдан",
          "Юридический адрес",
          "Номер свидетельства",
          "ОГРН"
      ]

      data.each do |row|
        csv << [
            row[:inn],
            row[:name],
            row[:short_name],
            row[:city],
            Exporter.statuses[row[:status]],
            row[:resolution_date],
            row[:legal_address],
            row[:certificate_number],
            row[:ogrn]
        ]
      end
    end
  end
end
