require 'spec_helper'

describe BookingRequirement do

  it 'should find by group and occasion' do
    group               = create(:group)
    occasion            = create(:occasion)
    booking_requirement = create(:booking_requirement, :group => group, :occasion => occasion)

    # dummies
    create(:booking_requirement)
    create(:booking_requirement, :group => group)
    create(:booking_requirement, :occasion => occasion)

    expect(BookingRequirement.get(group, occasion).id).to eql booking_requirement.id
  end
end