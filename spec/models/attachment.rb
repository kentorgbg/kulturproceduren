require 'spec_helper'

describe Attachment do
  it{ should validate_presence_of(:description).with_message('Beskrivningen får inte vara tom') }
  it{ should validate_presence_of(:filename).with_message('Filnamnet får inte vara tomt') }
  it{ should validate_presence_of(:content_type).with_message('Content type får inte vara tom') }
end