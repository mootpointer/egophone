require 'spec_helper'

describe Person do
  context 'with un-normalized australian number' do
    it 'normalizes the phone number' do
      p = Person.create(:phone_numbers => ["0423 729 698"])
      p.phone_numbers.should include("+61423729698")
    end
  end

  context 'with un-normalized US number' do
    it 'normalizes the phone number' do
      p = Person.create(:phone_numbers => ['+1 (260) 449-1522'])
      p.phone_numbers.should include('+12604491522')
    end
  end
end
