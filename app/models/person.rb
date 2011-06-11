class Person
  include Mongoid::Document
  field :phone_numbers, type: Array, default: []
  field :name, type: String

  before_save :normalize
  embeds_many :messages

  def messages_from
    messages.where(:direction => :in)
  end

  def messages_to
    messages.where(:direction => :out)
  end

  private
  def normalize
    phone_numbers.collect! do |phone|
      phone.gsub! /[^\d\+]/, ''
      unless phone[0] == '+'        
        case phone
        when /^0[24]/
          phone = "+61#{phone[1..-1]}"
        when /^0[78]/
          phone = "+27#{phone[1..-1]}"
        else
          phone = nil
        end
      end
      phone
    end
    phone_numbers.compact!
  end
end
