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
    def time_of_day(q="*:*")
      results = Message.search do 
       query {string q}

        size 0
        facet :time_of_day do 

          @value = {:histogram => {
            :key_script => "doc['sent'].date.hourOfDay",
            :value_script => 1}
          }
        end
      end
    counts = Hash.new(0)
    (0..23).each {|x| counts[x] = 0}
    
    results.facets["time_of_day"]["entries"].each {|x| counts.merge!({(x["key"] + 10) % 24 => x["count"]})}
    counts

    end

    def words(dir=:out)
      result = Message.search do
        query {string "*:*"}
        size 0
        facet :words do
          @value = {:terms => {
            :field => 'text',
            :size => 20,
            :script => "term.length() > 3 ? true : false"
          },
          :facet_filter => {:term => {:direction => dir}}}
        end
      end

      result.facets["words"]["terms"].collect {|term| [term["term"], term["count"]]}
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
