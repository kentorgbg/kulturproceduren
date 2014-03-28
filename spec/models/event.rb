require 'spec_helper'

describe Event do

  context 'validations' do
    it{ should validate_presence_of(:name).with_message         'Namnet får inte vara tomt' }
    it{ should validate_presence_of(:description).with_message  'Beskrivningen får inte vara tom' }
    it{ should validate_presence_of(:visible_from).with_message 'Du måste ange datum' }
    it{ should validate_presence_of(:visible_to).with_message   'Du måste ange datum' }
    it{ should validate_numericality_of(:from_age).with_message 'Åldern måste vara ett giltigt heltal' }
    it{ should validate_numericality_of(:to_age).with_message   'Åldern måste vara ett giltigt heltal' }
  end


  context 'class' do
    subject { Event }

    context '.standing vs .non_standing' do
      let!(:standing_events)     { create_list :event, 5 }
      let!(:non_standing_events) { create_list :event_with_occasions, 5 }
  
      it 'should only find events without occasions' do
        expect(subject.standing.to_a).to match_array(standing_events)
      end
  
      it 'should only find events with occasions' do
        expect(subject.non_standing.to_a).to match_array(non_standing_events)
      end
    end


    context '.without_tickets' do
      let!(:with)    { create :event }
      let!(:without) { create :event }
      before(:each)  { create :ticket, event: with }

      it 'should only find events without tickets' do
        expect(subject.without_tickets.to_a).to match_array [without]
      end
    end

    context '.without_questionnaires' do
      let!(:with)    { create :event }
      let!(:without) { create :event }
      before(:each)  { create :questionnaire, event: with }

      it 'should only find events without questionnaires' do
        expect(subject.without_questionnaires.to_a).to match_array [without]
      end
    end

    context '.not_linked_to_event' do
      let!(:event1) { create :event }
      let!(:event2) { create :event }
      let!(:event3) { create :event, linked_events: [event1] }

      it 'should only find events not linked to the given event' do
        expect(subject.not_linked_to_event(event3).to_a).to match_array [event2]
      end
    end

    context '.not_linked_to_culture_provider' do
      let!(:culture_provider) { create :culture_provider }
      let!(:event1)           { create :event }
      before(:each)           { create :event, linked_culture_providers: [culture_provider] }

      it 'should only find events not linked to the given culture provider' do
        expect(subject.not_linked_to_culture_provider(culture_provider).to_a).to match_array [event1]
      end
    end
  end


  context 'instance' do
    subject{ create :event }

    context '#booked_users' do
      let(:users) { create_list :user, 2 }
      before do
        create_list :ticket, 3, event: subject, user: users.first,  state: :booked
        create_list :ticket, 3, event: subject, user: users.first,  state: :unbooked
        create_list :ticket, 3, event: subject, user: users.second, state: :unbooked
      end

      it 'should return users with booked tickets' do
        expect(subject.booked_users.to_a).to match_array [users.first]
      end
    end

    context '#groups.find_by_district' do
      let(:districts){ create_list :district, 2 }
      before :each do
        districts.each do |d|
          create_list(:school, 2, district: d).each do |s|
            create_list(:group, 2, school: s).each do |g|
              create_list(:ticket, 2, district: d, group: g, event: subject)
            end
          end
        end
      end

      it 'should find groups for the given district' do
        district = districts.first
        groups   = subject.groups.find_by_district(district)
        groups.each{ |group| expect(group.school.district.id).to eql district.id }
      end
    end

    context '#reportable_occasions' do
      before :each do
        create_list :occasion, 5, event: subject, date: Date.today
        create_list :occasion, 6, event: subject, date: 1.day.ago.to_date
      end

      it 'should find all occasions for yesterday' do
        occasions = subject.reportable_occasions
        expect(occasions.count).to eql 6
        occasions.each{ |o| expect(o.date).to satisfy{ |date| date < Date.today } }
      end
    end

    context 'images' do
      let(:images)  { create_list :image, 10, event: subject }
      before(:each) { subject.main_image_id = images.first.id }

      it 'should return the main image' do
        expect(subject.main_image.id).to eql images.first.id
      end

      it 'should return images excluding main' do
        result = subject.images_excluding_main
        expect(result).not_to include(images.first)
        expect(result.count).to eql 9
      end
    end

    context 'further education age' do
      subject{ create :event, further_education: true, from_age: 10, to_age: 11 }
      it 'should override from_age' do
        expect(subject.from_age).to eql -1
      end
      it 'should override to_age' do
        expect(subject.to_age).to eql -1
      end
    end

    context 'ticket state' do
      subject        { Event.new }
      let(:integers) { {Event::ALLOTED_GROUP => :alloted_group, Event::ALLOTED_DISTRICT => :alloted_district, Event::FREE_FOR_ALL => :free_for_all } }
      let(:symbols)  { integers.values }

      it 'should assign ticket state using symbols' do
        symbols.each do |symbol|
          subject.ticket_state = symbol
          expect(subject.ticket_state).to eql symbol
          expect(subject.send("#{symbol}?")).to be_true
        end
      end

      it 'should assign ticket state using integers' do
        integers.each do |integer, symbol|
          subject.ticket_state = integer
          expect(subject.ticket_state).to eql symbol
          expect(subject.send("#{symbol}?")).to be_true
        end
      end

      it 'should not assign an invalid ticket state symbol' do
        subject.ticket_state = :zomg
        expect(subject.ticket_state).to be_nil
        expect(subject).not_to be_alloted_group
        expect(subject).not_to be_alloted_district
        expect(subject).not_to be_free_for_all
      end

      it 'should not assign an invalid ticket state integer' do
        subject.ticket_state = -3
        expect(subject.ticket_state).to be_nil
        expect(subject).not_to be_alloted_group
        expect(subject).not_to be_alloted_district
        expect(subject).not_to be_free_for_all
      end
    end

    context '#transition_to_district?' do
      context 'alloted group' do
        subject { create :event, ticket_state: :alloted_group }

        it 'should return true if transition date is today' do
          subject.district_transition_date = Date.today
          expect(subject).to be_transition_to_district
        end
        it 'should return true if transition date is in the past' do
          subject.district_transition_date = 1.day.ago.to_date
          expect(subject).to be_transition_to_district
        end
        it 'should return false if transition date is in the future' do
          subject.district_transition_date = 1.day.from_now.to_date
          expect(subject).not_to be_transition_to_district
        end
        it 'should return false if transition date is blank' do
          expect(subject).not_to be_transition_to_district
        end
      end
      context 'alloted district' do
        subject { create :event, ticket_state: :alloted_district, district_transition_date: Date.today }
        it 'should return false' do
          expect(subject).not_to be_transition_to_district
        end
      end
    end

    context '#transition_to_district!' do
      subject { create :event, ticket_state: :alloted_group, district_transition_date: Date.today }
      
      it 'should transition to district' do
        subject.transition_to_district!
        expect(subject.reload).to be_alloted_district
      end
    end

    context '#transition_to_free_for_all?' do
      context 'alloted district' do
        subject{ create :event, ticket_state: :alloted_district }
        
        it 'should return true if transition date is today' do
          subject.free_for_all_transition_date = Date.today
          expect(subject).to be_transition_to_free_for_all
        end
        it 'should return true if transition date is in the past' do
          subject.free_for_all_transition_date = 1.day.ago.to_date
          expect(subject).to be_transition_to_free_for_all
        end
        it 'should return false if transition date is in the future' do
          subject.free_for_all_transition_date = 1.day.from_now.to_date
          expect(subject).not_to be_transition_to_free_for_all
        end

      end
      context 'free for all' do
        subject{ create :event, ticket_state: :free_for_all, free_for_all_transition_date: Date.today }
        it 'should return false if already transitioned' do
          expect(subject).not_to be_transition_to_free_for_all
        end
      end
      context 'alloted group' do
        subject{ create :event, ticket_state: :alloted_group, free_for_all_transition_date: Date.today, district_transition_date: nil }
        it 'should return true if district transition date is blank' do
          expect(subject).to be_transition_to_free_for_all
        end
      end
    end

    context '#transition_to_free_for_all!' do
      subject{ create :event, ticket_state: :alloted_district, free_for_all_transition_date: Date.today }
      
      it 'should transition to free-for-all' do
        subject.transition_to_free_for_all!
        expect(subject.reload).to be_free_for_all
      end
    end

    context '#bookable?' do
      subject do
        create :event_with_occasions, visible_from:        1.day.ago.to_date,
                                      visible_to:          1.day.from_now.to_date,
                                      ticket_release_date: 1.day.ago.to_date
      end
      before(:each) { create_list :ticket, 5, event: subject }

      it{ should be_bookable }

      it 'should not be bookable if visible_from in the future' do
        subject.visible_from = 1.day.from_now.to_date
        expect(subject).not_to be_bookable
      end

      it 'should not be bookable if visible_to in the past' do
        subject.visible_to = 1.day.ago.to_date
        expect(subject).not_to be_bookable
      end

      it 'should not be bookable if ticket release date is blank' do
        subject.ticket_release_date = nil
        expect(subject).not_to be_bookable
      end

      it 'should not be bookable if ticket release date in the future' do
        subject.ticket_release_date = 1.day.from_now.to_date
        expect(subject).not_to be_bookable
      end

      it 'should be bookable if ticket release date in the past' do
        subject.ticket_release_date = 1.day.ago.to_date
        expect(subject).to be_bookable
      end

      it 'should not be bookable if no tickets' do
        subject.tickets.clear
        expect(subject).not_to be_bookable
      end

      it 'should not be bookable if no occasions' do
        subject.occasions.clear
        expect(subject).not_to be_bookable
      end

    end


  end

end