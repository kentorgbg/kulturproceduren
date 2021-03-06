require "kk/ftp_import/base"

class KK::FTP_Import::DistrictImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("DistrictImporter #{ENV['file']}: Wrong row length (#{row.length} fields, expected 2)") if row.length != 2

    {
      extens_id: row[0].try(:strip),
      name: row[1].try(:strip)
    }
  end

  def unique_id(attributes)
    attributes[:extens_id]
  end

  def build(attributes)
    base = District.where(school_type_id: @school_type_id)

    district = base.where(extens_id: attributes[:extens_id]).first
    district ||= District.new(school_type_id: @school_type_id)

    district.name = attributes[:name]
    district.extens_id = attributes[:extens_id]
    district.to_delete = false

    return district
  end
end
