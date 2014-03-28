require 'spec_helper'

describe CategoryGroup do
  it{ should validate_presence_of(:name).with_message 'Namnet får inte vara tomt' }
end
