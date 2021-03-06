require "kk/ftp_import/base"

class KK::FTP_Import::PreSchoolContactImporter < KK::FTP_Import::Base
  def initialize(csv, school_type_id, csv_header = false)
    super(csv, csv_header)
    @school_type_id = school_type_id
  end

  def attributes_from_row(row)
    raise KK::FTP_Import::ParseError.new("PreSchoolContactImporter #{ENV['file']}: Wrong row length (#{row.length} fields, expected 3)") if row.length != 3

    contact = row[1].try(:strip)
    return nil if contact.blank?

    {
      school_id: row[0].try(:strip),
      url: row[1].try(:strip),
      phone: row[2].try(:strip)
    }
  end

  # Contacts do not have unique ids
  def unique_id(attributes)
    nil
  end

  def build(attributes)
    #puts "#{@school_prefix+attributes[:school_id]}"

    school = School.includes(:district).references(:district)
      .where([ "districts.school_type_id = ?", @school_type_id ])
      .where(extens_id: attributes[:school_id]).first
    return nil unless school

    contacts = school.contacts.try(:split, ",") || []
    if !attributes[:contact].nil? && !attributes[:contact].match(/@/).nil?
      puts attributes[:contact]
      contacts << attributes[:contact]
    end
    school.contacts = contacts.uniq.sort.join(",")

    return school
  end
end
