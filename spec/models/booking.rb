require 'spec_helper'

describe Booking do

  context 'validations' do
    it{ should validate_presence_of(:group).with_message('Bokningen måste tillhöra en grupp') }
    it{ should validate_presence_of(:occasion).with_message('Bokningen måste tillhöra en föreställning') }
    it{ should validate_presence_of(:user).with_message('Bokningen måste tillhöra en användare') }
    it{ should validate_presence_of(:companion_name).with_message('Namnet får inte vara tomt') }
    it{ should validate_presence_of(:companion_email).with_message('Epostadressen får inte vara tom') }
    it{ should validate_presence_of(:companion_phone).with_message('Telefonnumret får inte vara tomt') }

    context 'bus booking' do
      before{ subject.stub(:bus_booking){ true } }
      it{ should validate_presence_of(:bus_stop).with_message('Du måste ange en hållplats') }
    end

    context 'no bus booking' do
      before{ subject.stub(:bus_booking){ false } }
      it{ should_not validate_presence_of(:bus_stop) }
    end


    context 'new booking' do
      context 'no seats' do
        subject{ build(:booking, student_count: 0, adult_count: 0, wheelchair_count: 0) }
  
        it 'should validate student count' do
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].join(" ")).to eql 'Du måste boka minst 1 plats'
        end
      end
  
      context 'too few available tickets' do
        subject{ build(:booking, :student_count => 1, :adult_count => 0, :wheelchair_count => 0, :skip_tickets => true) }
  
        it 'should validate student count' do
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du har bara 0 platser du kan boka på den här föreställningen'
        end
      end
  
      context 'too few seats' do
        subject do
          occasion = create(:occasion, seats: 10, wheelchair_seats: 3)
          build(:booking, occasion: occasion, student_count: 20, adult_count: 0, wheelchair_count: 0)
        end
  
        it 'should validate student count' do
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].join(" ")).to eql 'Du har bara 13 platser du kan boka på den här föreställningen'
        end
      end
  
      context 'too few wheelchair seats' do
        subject do
          occasion = create(:occasion, seats: 10, wheelchair_seats: 3)
          build(:booking, occasion: occasion, student_count: 1, adult_count: 0, wheelchair_count: 4)
        end
  
        it 'should validate wheelchair count' do
          expect(subject).not_to be_valid
          expect(subject.errors[:wheelchair_count].first).to eql 'Det finns bara 3 rullstolsplatser du kan boka på den här föreställningen'
        end
      end
  
      context 'wheelchair seats already booked' do
        subject do
          occasion = create(:occasion, seats: 10, wheelchair_seats: 3)
          create_list(:ticket, 2, occasion: occasion, wheelchair: true, state: :booked)
          build(:booking, occasion: occasion, student_count: 1, adult_count: 0, wheelchair_count: 2)
        end
  
        it 'should validate wheelchair count' do
          expect(subject).not_to be_valid
          expect(subject.errors[:wheelchair_count].first).to eql 'Det finns bara 1 rullstolsplatser du kan boka på den här föreställningen'
        end
      end
    end
  

    context 'existing booking' do

      context 'no seats' do
        subject{ create(:booking) }
        it{ should be_valid }

        it 'should validate student count' do
          subject.student_count = subject.adult_count = subject.wheelchair_count = 0
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du måste boka minst 1 plats'
        end
      end

      context 'too few tickets' do
        subject{ create(:booking) }
        it{ should be_valid }

        it 'should validate student count' do
          subject.student_count += 1
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du har bara 0 platser du kan boka på den här föreställningen'
        end
      end

      context 'too few seats' do
        let(:occasion) { create(:occasion, seats: 10, wheelchair_seats: 0) }
        subject        { create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0) }
        before(:each)  { create(:ticket, event: occasion.event, group: subject.group, state: :unbooked, wheelchair: false) }

        it{ should be_valid }

        it 'should validate student count' do
          subject.student_count += 1
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du har bara 0 platser du kan boka på den här föreställningen'
        end
      end

      context 'too few wheelchair seats' do
        let(:occasion) { create(:occasion, seats: 10, wheelchair_seats: 0) }
        subject        { create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0) }
        before(:each)  { create(:ticket, event: occasion.event, group: subject.group, state: :unbooked, wheelchair: false) }

        it{ should be_valid }
        
        it 'should validate wheelchair count' do
          subject.wheelchair_count += 1
          expect(subject).not_to be_valid
          expect(subject.errors[:wheelchair_count].first).to eql 'Det finns bara 0 rullstolsplatser du kan boka på den här föreställningen'
        end
      end

      context 'wheelchair seats already booked' do
        let(:occasion){ create(:occasion, seats: 10, wheelchair_seats: 2) }
        subject       { create(:booking, occasion: occasion, student_count: 8, adult_count: 2, wheelchair_count: 0) }
        before(:each) { create_list(:ticket, 2, occasion: occasion, wheelchair: true, state: :booked) }
        before(:each) { create(:ticket, event: occasion.event, group: subject.group, state: :unbooked, wheelchair: false) }

        it{ should be_valid }

        it 'should validate wheelchair count' do
          subject.wheelchair_count += 1
          expect(subject).not_to be_valid
          expect(subject.errors[:wheelchair_count].first).to eql 'Det finns bara 0 rullstolsplatser du kan boka på den här föreställningen'
        end
      end

      context 'include deactivated tickets in the validation, for group allotment' do
        let(:occasion){ create(:occasion, single_group: true) }
        subject       { create(:booking,  occasion: occasion) }
        before(:each) { create(:ticket, event: occasion.event, group: subject.group, state: :deactivated, booking: subject) }
        before(:each) { subject.tickets(true) } # reload association

        it{ should be_valid }

        it 'should validate student count' do
          subject.student_count += 2
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du har bara 1 platser du kan boka på den här föreställningen'
        end 
      end

      context 'include deactivated tickets in the validation, the other allotment states' do
        let!(:occasion) { o = create(:occasion, single_group: true); o.event.ticket_state = :alloted_district; o }
        subject         { create(:booking, occasion: occasion) }
        before(:each)   { create(:ticket, event: occasion.event, group: subject.group, state: :deactivated, booking: subject) }
        before(:each)   { subject.tickets(true) } # Reload association

        it{ should be_valid }

        it 'should validate student count' do
          subject.student_count += 2
          expect(subject).not_to be_valid
          expect(subject.errors[:student_count].first).to eql 'Du har bara 1 platser du kan boka på den här föreställningen'
        end
      end
    end
  end


  context 'callbacks' do

    let(:occasion) { create(:occasion, single_group: true) }
    subject        { build(:booking, occasion: occasion, student_count: 15, adult_count: 3, wheelchair_count: 2) }

    before(:each) do
      create_list(:ticket, 10,
        booking:  nil, 
        group:    subject.group,
        district: subject.group.school.district,
        occasion: occasion,
        event:    subject.occasion.event,
        state:    :unbooked
      )
    end



    it 'should synchronize tickets' do

      #New booking
      expect(subject.save).to be_true
      subject.tickets(true)

      expect(Ticket.booked.count).to      eql 20
      expect(Ticket.deactivated.count).to eql 10
      expect(subject.student_count).to    eql Ticket.booked.where(adult: false, wheelchair: false).count
      expect(subject.adult_count).to      eql Ticket.booked.where(adult: true,  wheelchair: false).count
      expect(subject.wheelchair_count).to eql Ticket.booked.where(adult: false, wheelchair: true).count

      ## Existing booking, fewer tickets
      subject.student_count    -= 1
      subject.adult_count      -= 1
      subject.wheelchair_count -= 1
    
      expect(subject.save).to be_true
      subject.tickets(true)

      expect(Ticket.booked.count).to      eql 17
      expect(Ticket.deactivated.count).to eql 13

      expect(subject.student_count).to    eql Ticket.booked.where(adult: false, wheelchair: false).count
      expect(subject.adult_count).to      eql Ticket.booked.where(adult: true,  wheelchair: false).count
      expect(subject.wheelchair_count).to eql Ticket.booked.where(adult: false, wheelchair: true).count

      ## Existing booking, more tickets
      subject.student_count    += 2
      subject.adult_count      += 2
      subject.wheelchair_count += 2
  
      expect(subject.save).to be_true

      subject.tickets(true)

      expect(Ticket.booked.count).to      eql 23
      expect(Ticket.deactivated.count).to eql 7
   
      expect(subject.student_count).to eql    Ticket.booked.where(adult: false, wheelchair: false).count
      expect(subject.adult_count).to eql      Ticket.booked.where(adult: true,  wheelchair: false).count
      expect(subject.wheelchair_count).to eql Ticket.booked.where(adult: false, wheelchair: true).count

      # Unbook
      subject.unbooked = true
      expect(subject.save).to be_true
      Ticket.all.each { |t| expect(t).to be_unbooked }
    end


    it 'should set booked at timestamp' do
      before = Time.now
      expect(subject.save).to be_true
      after = Time.now
      expect(subject.booked_at).to satisfy{ |v| v >= before && v <= after }
    end
  end


  context 'scopes' do

    subject         { Booking }
    let!(:active)   { create(:booking, unbooked: false) }
    let!(:inactive) { create(:booking, unbooked: true) }

    it 'should find active' do
      expect(subject.active.to_a).to eql [active]
    end
  end


  context 'counts' do

    subject{ build(:booking, :student_count => nil, :adult_count => nil, :wheelchair_count => nil) }
    
    it 'should default count to zero' do
      expect(subject.student_count).to    be_zero
      expect(subject.adult_count).to      be_zero
      expect(subject.wheelchair_count).to be_zero
    end
  end


  context 'finder methods' do
    subject{ create(:booking) }

    it 'should find for user' do
      expect(Booking.find_for_user(subject.user, 1).to_a).to eql [subject]
    end

    it 'should find for group' do
      expect(Booking.find_for_group(subject.group, 1).to_a).to eql [subject]
    end

    it 'should find for event' do
      booking = create(:booking, unbooked: true)
      expect(Booking.find_for_event(booking.occasion.event.id, {}, 1).to_a).to eql [booking]

      booking = create(:booking, occasion: booking.occasion, unbooked: false)
      found   = Booking.find_for_event(booking.occasion.event.id, {unbooked: false}, 1).to_a
      expect(found).to eql [booking]

      booking = create(:booking, occasion: booking.occasion, unbooked: false)
      options = {unbooked: true, district_id: booking.group.school.district.id}
      found   = Booking.find_for_event(booking.occasion.event.id, options, 1).to_a
      expect(found).to eql [booking]
    end

    it 'should find for occasion' do
      booking = create(:booking, unbooked: true)
      expect(Booking.find_for_occasion(booking.occasion.id, {}, 1).to_a).to eql [booking]
  
      booking = create(:booking, occasion: booking.occasion, unbooked: false)
      expect(Booking.find_for_occasion(booking.occasion.id, {unbooked: false}, 1).to_a).to eql [booking]
  
      booking = create(:booking, occasion: booking.occasion, unbooked: false)
      options = {unbooked: true, district_id: booking.group.school.district.id}
      expect(Booking.find_for_occasion(booking.occasion.id, options, 1).to_a).to eql [booking]
    end

  end


  it 'should generate bus booking csv' do
    booking  = create(:booking, bus_booking: true, bus_stop: "Bus stop", bus_one_way: false)
    expected = "Evenemang\tDatum\tAdress\tStadsdel\tSkola\tGrupp\tMedföljande vuxen\tTelefonnummer\tE-postadress\tAntal platser\tResa\tHållplats\n#{booking.occasion.event.name}\t#{booking.occasion.date.strftime("%Y-%m-%d")} #{booking.occasion.start_time.strftime("%H:%M")}\t#{booking.occasion.address}\t#{booking.group.school.district.name}\t#{booking.group.school.name}\t#{booking.group.name}\t#{booking.companion_name}\t#{booking.companion_phone}\t#{booking.companion_email}\t#{booking.total_count}\tTur och retur\tBus stop\n"
    actual   = Booking.bus_booking_csv([booking])
    expect(actual).to eql expected
  end

end