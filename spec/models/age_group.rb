require 'spec_helper'

describe AgeGroup do

  context 'factory' do

    subject { build(:age_group) }
    it{ should be_valid }
  
  end


  context 'validation' do

    it{ should validate_numericality_of(:age).with_message('Åldern måste vara ett giltigt heltal.') }
    it{ should validate_numericality_of(:quantity).with_message('Antalet måste vara ett giltigt heltal.') }
  end


  context '.with_district' do

    let(:district){ create(:district_with_age_groups) }

    it "should find with district" do
      age_groups = AgeGroup.with_district(district.id)
  
      expect(age_groups).not_to be_blank
      expect(age_groups.pluck(:district_id).uniq).to eql([district.id])
    end
  end


  context '.with_age' do

    before :each do
      create(:age_group, :age => 8,  :quantity => 20)
      create(:age_group, :age => 9,  :quantity => 20)
      create(:age_group, :age => 10, :quantity => 30)
      create(:age_group, :age => 11, :quantity => 30)
    end

    it 'should find with age' do
      age_groups = AgeGroup.with_age(9, 10)

      expect(age_groups).not_to be_blank
      expect(age_groups.pluck(:age).sort).to eql([9, 10])
    end
  end


  context '.active' do

    it 'should only find active' do
      create(:group_with_age_groups, active: true)
      create(:group_with_age_groups, active: false)
      
      age_groups = AgeGroup.active
      
      expect(AgeGroup.active).not_to be_blank
      expect(AgeGroup.active.map{ |q| q.group.active}).to eql([true])
    end
  end


  context '.num_children_per_district' do
    
    let!(:district_1){ create(:district_with_age_groups, school_count: 2, group_count: 2, age_group_data: [[10, 10], [11, 20]]) }
    let!(:district_2){ create(:district_with_age_groups, school_count: 3, group_count: 3, age_group_data: [[10, 5],  [11, 15]]) }

    it 'should count the number of children per district' do
      counts = AgeGroup.num_children_per_district

      expect(counts[district_1.id.to_s]).to eql 2*2*10 + 2*2*20
      expect(counts[district_2.id.to_s]).to eql 3*3*5 + 3*3*15
    end
  end


  context '.num_children_per_group' do

    let!(:group_1){ create(:group_with_age_groups, age_group_data: [[10, 10], [11, 20]]) }
    let!(:group_2){ create(:group_with_age_groups, age_group_data: [[10, 5],  [11, 15]]) }

    it 'should count the number of children by group' do
      counts = AgeGroup.num_children_per_group
      
      expect(counts[group_1.id]).to eql 10+20
      expect(counts[group_2.id]).to eql 5+15
    end
  end

end