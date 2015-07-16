require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolDistrictImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("Wrong row length (#{row.length} fields, expected 5)") if row.length != 5

    {
      name: row[3].try(:strip)
    }
  end

  def build(attributes)
    base = District.where(school_type_id: @school_type_id)

    district = base.where(name: attributes[:name]).first
    district ||= District.new(school_type_id: @school_type_id)

    district.name = attributes[:name]
    district.extens_id = "Pre-School-District-" + attrifutes[:name]

    return district
  end
end
