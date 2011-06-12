class Message
  include Mongoid::Document
    
  include Tire::Model::Search
  include Tire::Model::Callbacks

  before_save :normalize
  field :phone, :type =>  String
  field :direction, :type =>  Symbol
  field :text, :type =>  String
  field :sent, :type =>  DateTime


  embedded_in :person
  
  mapping do
    indexes :id,         :type => 'string', :index => 'not_analyzed', :include_in_all => false
    indexes :direction,  :type => 'string', :index => 'not_analyzed'
    indexes :text,       :type => 'string', :term_vector => 'yes'
    indexes :sent,       :type => 'date'
    indexes :phone,      :type => 'string', :index => 'not_analyzed'
    indexes :person_id,  :type => 'string', :index => 'not_analyzed'
  end

  class << self
    def time_of_day
      Message.search do 
        query {string "*:*"}
        size 0
        facet :time_of_day do 

          @value = {:histogram => {
            :key_script => "doc['sent'].date.hourOfDay",
            :value_script => 1}
          }
        end
      end

    end
  end

  def set_person
    @person_id = person.id
  end

  def normalize
    country_map = {'au' => '+61', 'hk' => '+82', 'kz' => '+7'}
    phone.gsub! /\s/, ''
    unless phone[0] == '+'
      self.phone = country_map[country] + phone[1..-1]
    end
  end

  
end
