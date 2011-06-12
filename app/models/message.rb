class Message
  include Mongoid::Document
    
  include Tire::Model::Search
  include Tire::Model::Callbacks


  before_save :normalize
  field :phone, type: String
  field :direction, type: Symbol
  field :text, type: String
  field :sent, type: DateTime

  embedded_in :person


  def normalize
    country_map = {'au' => '+61', 'hk' => '+82', 'kz' => '+7'}
    phone.gsub! /\s/, ''
    unless phone[0] == '+'
      self.phone = country_map[country] + phone[1..-1]
    end
  end

  
end
