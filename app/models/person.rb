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
  
  class << self
    def top
      map = '
      function() {
        if(this.messages) for(i in this.messages) {
          emit(this.name, 1);          
        }
      }
      '

      reduce = '
      function(key, values) {
        var sum = 0;
        for(var i=0; i<values.length; i++) {
          sum += values[i];
        }
        return sum;
      }'

      collection.mapreduce(map, reduce, :out => 'top')
    end

    def avg_chars
      map = '
      function() {
        if (this.messages) for(i in this.messages) {
          var msg = this.messages[i];
          if(msg.text) emit(this.name, {sum: msg.text.length, recs: 1});
        }
      }'
      reduce = '
      function(key, values) {
        var ret = {sum: 0, recs: 0};
        for(var i=0; i<values.length; i++) {
          ret.sum += values[i].sum;
          ret.recs += values[i].recs;
        }
        return ret;
      }'

      finalize = '
      function(key, values) {
        values.avg = values.sum / values.recs
        return values;
      }'

      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'avg_chars')
    end

    def avg_word_length
      map = '
      function() {
        if (this.messages) for(i in this.messages) {
          var msg = this.messages[i];
          if(msg.text) emit(this.name, {words: msg.text.split(" ").length, chars: msg.text.replace(" ", "").length});
        }
      }'
      reduce = '
      function(key, values) {
        var ret = {chars: 0, words: 0};
        for(var i=0; i<values.length; i++) {
          ret.chars += values[i].chars;
          ret.words += values[i].words;
        }
        return ret;
      }'

      finalize = '
      function(key, values) {
        values.avg = values.chars / values.words
        return values;
      }'
      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'avg_word_length')      
    end

    def direction
      map = '
      function() {
        if (this.messages) for(i in this.messages) {
          var em = {in: 0, out : 0}
          var msg = this.messages[i];
          if (msg.direction == "in") {em.in = 1;} else {em.out = 1;}
          if(msg.text) emit(this.name, em);
        }
      }'
      reduce = '
      function(key, values) {
        var ret = {in: 0, out: 0};
        for(var i=0; i<values.length; i++) {
          ret.in += values[i].in;
          ret.out += values[i].out;
        }
        return ret;
      }'
      finalize = '
      function(key, values) {
        values.ratio = values.in / values.out
        return values;
      }
      '
      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'direction')            

    end

    def words 
      map = '
      function() {
        if (this.messages) for(i in this.messages) {
          var em = {in: 0, out : 0}
          var msg = this.messages[i];
          if (msg.direction == "in") {em.in = 1;} else {em.out = 1;}
          if(msg.text) {
            var words = msg.text.split(" ")
            for (var w in words) {
            var word = words[w];
            stripped = word.replace("\\n", " ").replace(/\W/g, "").toLowerCase();
            emit(stripped, em);
            }
          }
        }
      }'
      reduce = '
      function(key, values) {
        var ret = {in: 0, out: 0};
        for(var i=0; i<values.length; i++) {
          ret.in += values[i].in;
          ret.out += values[i].out;
        }
        return ret;
      }'

      collection.mapreduce(map, reduce, :out => 'words')            

    end
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
