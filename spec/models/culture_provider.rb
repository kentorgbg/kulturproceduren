require 'spec_helper'

describe CultureProvider do

  it{ should validate_presence_of(:name).with_message 'Namnet får inte vara tomt' }

  
  context 'standing events' do
    subject{ create :culture_provider }

    before do
      create_list :event, 5,                culture_provider: subject
      create_list :event_with_occasions, 5, culture_provider: subject
    end
    
    it 'should find events without occasions' do
      expect(subject.events.count).to          eql 10
      expect(subject.standing_events.count).to eql 5
    end
  end


  context 'upcoming occasions' do
    subject{ create :culture_provider }

    before do
      create :event_with_occasions,
        culture_provider: subject,
        visible_from:     3.days.ago.to_date,
        visible_to:       2.days.ago.to_date,
        occasion_dates:   [1.day.from_now.to_date]
      event = create :event_with_occasions, culture_provider: subject, occasion_dates: [1.days.ago.to_date]
      create_list :occasion, 5, date: 1.day.from_now.to_date, event: event
    end

    it 'should only find upcoming occasions' do
      expect(subject.upcoming_occasions.count).to eql 5
      subject.upcoming_occasions.each do |occasion|
        expect(occasion.date).to satisfy{ |date| date >= Date.today }
      end
    end
  end


  context 'images' do
    subject       { create :culture_provider }
    let(:images)  { create_list :image, 10, culture_provider: subject }
    before(:each) { subject.main_image_id = images.first.id }

    it 'should return main image' do
      expect(subject.main_image.id).to eql images.first.id
    end

    it 'should return images excluding main' do
      expect(subject.images_excluding_main.count).to equal 9
      expect(subject.images_excluding_main.to_a).to match_array images[1..-1]
    end
  end


  context 'linked culture providers' do
    subject                  { CultureProvider }
    let!(:culture_provider1) { create :culture_provider }
    let!(:culture_provider2) { create :culture_provider }
    let!(:culture_provider3) { create :culture_provider, linked_culture_providers: [culture_provider1] }

    it 'should return culture providers not linked to culture provider 3' do
      expect(subject.not_linked_to_culture_provider(culture_provider3).to_a).to eql [culture_provider2]
    end
  end


  context 'linked events' do
    subject                 { CultureProvider }
    let!(:event)            { create :event }
    let!(:culture_provider) { create :culture_provider }
    before                  { create :culture_provider, linked_events: [event] }

    it 'should return culture providers not linked to an event' do
      expect(subject.not_linked_to_event(event).to_a).to eql [culture_provider]
    end
  end

end