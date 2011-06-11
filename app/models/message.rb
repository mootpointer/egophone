class Message
  include Mongoid::Document
  before_save :normalize

  field :phone, type: String
  field :direction, type: Symbol
  field :text, type: String
  field :sent, type: DateTime

  embedded_in :person

  def self.message_counts
    map = '
      function() {
        emit(this.person_id, 1);
      }'
        
    reduce = '
      function(key, values) {
        var sum = 0;
        for(var i=0; i<values.length; i++) {
          sum += values[i];
        }
        return sum;
      }'
    msg_counts = collection.map_reduce(map, reduce, :out => 'msg_counts')
  end  


  def normalize
    country_map = {'au' => '+61', 'hk' => '+82', 'kz' => '+7'}
    phone.gsub! /\s/, ''
    unless phone[0] == '+'
      self.phone = country_map[country] + phone[1..-1]
    end
  end

  
end
