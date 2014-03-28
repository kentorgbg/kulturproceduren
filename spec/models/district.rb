require 'spec_helper'

describe District do
  
  subject{ create :district }

  it{ should validate_presence_of(:name).with_message 'Namnet får inte vara tomt' }


  context 'schools' do

    let(:forskola)     { create :school, district: subject }
    let(:lagstadie)    { create :school, district: subject }
    let(:mellanstadie) { create :school, district: subject }

    before :each do
      create :group_with_age_groups, school: forskola, age_group_data: [[3, 1], [4, 1]]
      create :group_with_age_groups, school: forskola, age_group_data: [[5, 1], [6, 1]]
      create :group_with_age_groups, school: forskola, age_group_data: [[1, 1]], active: false

      create :group_with_age_groups, school: lagstadie, age_group_data: [[7, 1]]
      create :group_with_age_groups, school: lagstadie, age_group_data: [[8, 1]]
      create :group_with_age_groups, school: lagstadie, age_group_data: [[9, 1]]
      create :group_with_age_groups, school: lagstadie, age_group_data: [[1, 1]], active: false

      create :group_with_age_groups, school: mellanstadie, age_group_data: [[10, 1]]
      create :group_with_age_groups, school: mellanstadie, age_group_data: [[11, 1]]
      create :group_with_age_groups, school: mellanstadie, age_group_data: [[12, 1]]
      create :group_with_age_groups, school: mellanstadie, age_group_data: [[1, 1]], active: false
    end

    it 'should find schools by age span 8-11' do
      schools = subject.schools.find_by_age_span(8, 11)
      expect(schools).not_to be_blank
      schools.each{ |school| expect(school).to satisfy{ |school| school.age_groups.exists?(age: (8..11)) } }
    end

    it 'should find schools by age span 6-7' do
      schools = subject.schools.find_by_age_span(6, 7)
      expect(schools).not_to be_blank
      schools.each{ |school| expect(school).to satisfy{ |school| school.age_groups.exists?(age: (6..7)) } }
    end

    it 'should not find inactive schools' do
      expect(subject.schools.find_by_age_span(1,2)).to be_blank
    end
  end


  context 'available tickets by occasion' do
    let(:occasion) { create :occasion }
    before :each do
      create_list :ticket, 5, event: occasion.event, district: subject, state: :unbooked
      create_list :ticket, 5, event: occasion.event, district: subject, state: :booked
      create_list :ticket, 5, event: occasion.event, state: :unbooked
      create_list :ticket, 5, event: occasion.event, state: :booked
    end

    it 'should count available tickets when allotted group' do
      occasion.event.update_attribute :ticket_state, :alloted_group
      expect(subject.available_tickets_by_occasion(occasion)).to eql 5
    end

    it 'should count available tickets when allotted district' do
      occasion.event.update_attribute :ticket_state, :alloted_district
      expect(subject.available_tickets_by_occasion(occasion)).to eql 5
    end

    it 'should count available tickets when free-for-all' do
      occasion.event.update_attribute :ticket_state, :free_for_all
      expect(subject.available_tickets_by_occasion(occasion)).to eql 10
    end

  end

end