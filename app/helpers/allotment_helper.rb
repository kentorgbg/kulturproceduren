module AllotmentHelper
  # Returns a CSS class indicating whether a row has a partial
  # or full allotment of tickets.
  def fill_indicator(num_children, num_tickets)
    if num_tickets > 0 && num_tickets < num_children
      return "partial"
    elsif num_tickets > 0 && num_tickets >= num_children
      return "full"
    end
  end
end
