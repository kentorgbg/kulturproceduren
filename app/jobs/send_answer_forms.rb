class SendAnswerForms

  def initialize(today, activation_days)
    @today, @activation_days = today, activation_days
  end

  def run
    occasions = Occasion.where(date: @today - @activation_days, cancelled: false).includes(:event)
    
    occasions.each do |occasion|
      occasion.bookings.active.each do |booking|
        if booking.answer_form && !booking.answer_form.try(:completed)
          OccasionMailer.answer_form_email(occasion, booking).deliver
          puts "Sending mail about evaluation form for #{occasion.event.name}, #{occasion.date} to #{booking.companion_email}"
        end
      end
    end
  end
end