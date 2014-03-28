require 'spec_helper'

describe Category do
  it{ should validate_presence_of(:name).with_message 'Namnet får inte vara tomt' }  
end
