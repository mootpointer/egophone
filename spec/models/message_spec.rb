require 'spec_helper'

describe Message do
  context 'with a non-normalized Australian number' do
    it 'normalizes a normalized number' do
      m = Message.create :phone => '0423 729 698', :country => 'au'
      m.phone.should == '+61423729698'
    end
  end
end
