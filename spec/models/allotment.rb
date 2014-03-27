require 'spec_helper'

describe Allotment do

  context 'factory' do
    subject { build(:allotment) }
    it{ should be_valid }
  end


  context 'validations' do
    it{ should validate_presence_of(:user).with_message('Tilldelningen måste tillhöra en grupp') }
    it{ should validate_presence_of(:event).with_message('Tilldelningen måste tillhöra ett evenemang') }
  end


  context 'callbacks' do
    
    let(:group)     { create(:group) }
    let(:allotment) { build(:allotment, group: group, district: group.school.district) }

    it 'should synchronize tickets after save' do
      expect(allotment.save).to be_true
      expect(allotment.amount).to eql Ticket.count
      expect(allotment.amount).to_not be_zero
      
      Ticket.all.each do |ticket|
        expect(ticket.event.id).to    eql allotment.event.id
        expect(ticket.district.id).to eql allotment.district.id
        expect(ticket.group.id).to    eql allotment.group.id
        
        expect(ticket).to be_unbooked
        expect(ticket.adult).to be_false
        expect(ticket.wheelchair).to be_false
      end
    end
  end


  context 'instance methods' do

    let(:group)              { create(:group) }
    let(:group_allotment)    { build(:allotment, group: group) }
    let(:district_allotment) { build(:allotment, district: group.school.district) }
    let(:for_all_allotment)  { build(:allotment) }


    it 'should give correct allotment type' do
      expect(group_allotment.allotment_type).to eql    :group
      expect(district_allotment.allotment_type).to eql :district
      expect(for_all_allotment.allotment_type).to eql  :free_for_all
    end

    context '#for_group?' do
      subject{ group_allotment }

      it{ should     be_for_group }
      it{ should_not be_for_district }
      it{ should_not be_for_all }
    end

    context '#for_district?' do
      subject{ district_allotment }

      it{ should_not be_for_group }
      it{ should     be_for_district }
      it{ should_not be_for_all }
    end

    context '#for_all?' do
      subject{ for_all_allotment }

      it{ should_not be_for_group }
      it{ should_not be_for_district }
      it{ should     be_for_all }
    end


  end

end