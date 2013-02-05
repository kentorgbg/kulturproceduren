class AttendanceController < ApplicationController
  layout "standard"

  before_filter :authenticate
  before_filter :load_entity

  before_filter :require_host, :only => [ :report, :update_report ]

  # Lists the attendance of an event or a single occasion
  def index
    if params[:format] == "pdf"
      send_data generate_pdf().render, :filename => "narvaro.pdf", :type => "application/pdf", :disposition => "inline"
    end
  end

  # Displays a form for reporting attendance
  def report
    if @occasion && @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to occasion_attendance_index_url(@occasion)
      return
    end
  end

  # Updates the attendance report
  def update_report
    if @occasion && @occasion.date >= Date.today
      flash[:error] = "Du kan inte rapportera närvaro på en föreställning som ännu inte har varit"
      redirect_to root_url()
      return
    end

    (@occasion ? [@occasion] : @event.reportable_occasions).each do |occasion|
      groups = occasion.attending_groups

      groups.each do |group|
        attendance = {}
        params[:attendance][occasion.id.to_s][group.id.to_s].each do |k,v|
          attendance[k.to_sym] = v.to_i unless v.blank?
        end

        tickets = Ticket.find_not_unbooked(group, occasion)

        tickets.each do |ticket|
          if ticket.adult
            if attendance.has_key?(:adult)
              ticket.state = attendance[:adult] > 0 ? Ticket::USED : Ticket::NOT_USED
              attendance[:adult] -= 1
            else
              ticket.state = Ticket::BOOKED
            end
          elsif ticket.wheelchair
            if attendance.has_key?(:wheelchair)
              ticket.state = attendance[:wheelchair] > 0 ? Ticket::USED : Ticket::NOT_USED
              attendance[:wheelchair] -= 1
            else
              ticket.state = Ticket::BOOKED
            end
          else
            if attendance.has_key?(:normal)
              ticket.state = attendance[:normal] > 0 ? Ticket::USED : Ticket::NOT_USED
              attendance[:normal] -= 1
            else
              ticket.state = Ticket::BOOKED
            end
          end

          ticket.save!
        end

        # Create extra tickets for extra attendants
        [ :adult, :wheelchair, :normal ].each do |type|
          if attendance.has_key?(type) && attendance[type] > 0
            create_extra_tickets(attendance[type], tickets[0], type) 
          end
        end
      end
    end

    flash[:notice] = "Närvaron uppdaterades."
    if @occasion
      redirect_to report_occasion_attendance_url(@occasion)
    else
      redirect_to report_event_attendance_url(@event)
    end
  end

  protected

  # Loads either the requested event or the requested occasion
  def load_entity
    if !params[:event_id].blank?
      @event = Event.find params[:event_id]
    elsif !params[:occasion_id].blank?
      @occasion = Occasion.find params[:occasion_id], :include => :event
      @event = @occasion.event
    else
      flash[:error] = "Felaktig adress angiven"
      redirect_to root_url()
    end
  end

  # Checks if the user is a host. For use in <tt>before_filter</tt>.
  def require_host
    unless current_user.has_role?(:host) || current_user.has_role?(:admin)
      flash[:error] = "Du har inte behörighet att rapportera närvaro"
      redirect_to root_url()
      return
    end
  end

  private

  # Creates a pdf document of the attendants on an occasion or event
  def generate_pdf
    pdf = PDF::Writer.new :paper => "A4", :orientation => :landscape
    pdf.select_font("Helvetica")
    pdf.margins_cm(2, 2, 2, 2)

    (@occasion ? [ @occasion ] : @event.occasions).each do |occasion|
      PDF::SimpleTable.new do |tab|
        tab.title = "Deltagarlista för #{occasion.event.name}, föreställningen #{occasion.date.to_s} kl #{l(occasion.start_time, :format => :only_time)}".to_iso

        tab.column_order.push(*%w(group comp att_normal att_adult att_wheel req pres_normal pres_adult pres_wheel))

        tab.columns["group"] = PDF::SimpleTable::Column.new("group") { |col|
          col.heading = "Skola / Grupp".to_iso
          col.width = 130
        }
        tab.columns["comp"] = PDF::SimpleTable::Column.new("com") { |col|
          col.heading = "Medföljande vuxen".to_iso
          col.width = 180
        }
        tab.columns["att_normal"] = PDF::SimpleTable::Column.new("att_normal") { |col|
          col.heading = "Barn"
        }
        tab.columns["att_adult"] = PDF::SimpleTable::Column.new("att_adult") { |col|
          col.heading = "Vuxna"
        }
        tab.columns["att_wheel"] = PDF::SimpleTable::Column.new("att_wheel") { |col|
          col.heading = "Rullstol"
        }
        tab.columns["req"]  = PDF::SimpleTable::Column.new("req") { |col|
          col.heading = "Övriga önskemål".to_iso
          col.width = 130
        }
        tab.columns["pres_normal"]  = PDF::SimpleTable::Column.new("pres_normal") { |col|
          col.heading = "Barn".to_iso
        }
        tab.columns["pres_adult"]  = PDF::SimpleTable::Column.new("pres_adult") { |col|
          col.heading = "Vuxna".to_iso
        }
        tab.columns["pres_wheel"]  = PDF::SimpleTable::Column.new("pres_wheel") { |col|
          col.heading = "Rullstol".to_iso
        }

        tab.show_lines = :all
        tab.orientation = 1
        tab.position = :left
        tab.font_size = 9
        tab.heading_font_size = 9
        tab.maximum_width = 1
        tab.title_gap = 10
        tab.show_headings = true
        tab.heading_color = Color::RGB::White
        tab.shade_headings = true
        tab.shade_heading_color = Color::RGB::Grey30

        data = []

        occasion.bookings.school_ordered.each do |booking|
          data << create_pdf_row(occasion, booking)
        end

        if data.blank?
          # Add empty row
          data << {
            "group" => " ".to_iso,
            "comp" => " ".to_iso,
            "att_normal" => " ".to_iso,
            "att_adult" => " ".to_iso,
            "att_wheel" => " ".to_iso,
            "req" => " ".to_iso,
            "pres_normal" => " ".to_iso,
            "pres_adult" => " ".to_iso,
            "pres_wheel" => " ".to_iso
          }
        end

        tab.data.replace data
        tab.render_on(pdf)
      end
    end

    return pdf
  end

  def create_pdf_row(occasion, booking)
    row = {}
    row["group"] = (booking.group.school.name.to_s + " - " + booking.group.name.to_s).to_iso
    row["comp"] = "#{booking.companion_name}\n#{booking.companion_phone}\n#{booking.companion_email}".to_iso
    row["att_normal"] = booking.student_count || 0
    row["att_adult"] = booking.adult_count || 0
    row["att_wheel"] = booking.wheelchair_count || 0
    row["req"] = (booking.requirement.blank? ? " " : booking.requirement).to_iso
    row["pres_normal"] = " ".to_iso
    row["pres_adult"] = " ".to_iso
    row["pres_wheel"] = " ".to_iso

    return row
  end

  # Creates extra tickets for unannounced attendants when reporting attendance
  def create_extra_tickets(attendance, base, type)
    1.upto(attendance) do |i|
      ticket = Ticket.new do |t|
        t.state = Ticket::USED
        t.group = base.group
        t.user = current_user
        t.occasion = base.occasion
        t.event = base.event
        t.district = base.district
        t.booking = base.booking
        t.adult = (type == :adult)
        t.wheelchair = (type == :wheelchair)
        t.booked_when = DateTime.now
      end

      ticket.save!
    end
  end

end
