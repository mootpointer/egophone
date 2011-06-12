class Person
  include Mongoid::Document
  field :phone_numbers, :type => Array, :default => []
  field :name, :type => String

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

      collection.mapreduce(map, reduce, :out => 'top').find()
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

      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'avg_chars').find()
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
      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'avg_word_length').find()      
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
      collection.mapreduce(map, reduce, :finalize => finalize, :out => 'direction').find()            

    end

    def words(opts = {:out => 'words'}) 
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
            stripped = word.replace("\\n", " ").replace(/[^\w\']/g, "").toLowerCase();
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
    
      collection.mapreduce(map, reduce, opts).find()            

    end

  end

  def words
    phones = phone_numbers
    result = Message.search do
      query {string "*:*"}
      size  0
      filter :terms, :phone => phones
      facet :words do
        @value = {:terms => {
          :field => 'text',
          :size => 20
        }}
      end
    end
    
    result.facets["words"]["terms"].collect {|term| [term["term"], term["count"]]}
  end

  def stats(q="*:*")
    phones = phone_numbers
    result = Message.search do 
      query {string q}
      size 0
      filter :terms, :phone => phones
      facet :time_of_day do 

        @value = {:histogram => {
          :key_script => "doc['sent'].date.hourOfDay",
          :value_script => 1},
          :facet_filter => {:term => {:phone => phones}}
        }
      end
      facet :words_out do
        @value = {:terms => {
          :field => 'text',
          :size => 20,
        }, 
          :facet_filter => {:and => [{:term => {:phone => phones}}, {:term => {:direction => :out}}]}
        
        }
      end
      facet :words_in do
        @value = {:terms => {
          :field => 'text',
          :size => 20,

        }, 
          :facet_filter => {:and => [{:term => {:phone => phones}}, {:term => {:direction => :in}}]}
        
        }
      end
    end
    counts = Hash.new(0)
    w_in = result.facets["words_in"]["terms"].collect {|term| [term["term"], term["count"]]}
    w_out = result.facets["words_out"]["terms"].collect {|term| [term["term"], term["count"]]}
    result.facets["time_of_day"]["entries"].each {|x| counts.merge!({x["key"] => x["count"]})}

    {:time_of_day => counts, :words_received => w_in, :words_sent => w_out}

  end

  def time_of_day(q="*:*")
    phones = phone_numbers
    result = Message.search do 
      query {string q}
      size 0
      filter :terms, :phone => phones
      facet :time_of_day do 
        
        @value = {:histogram => {
                                  :key_script => "doc['sent'].date.hourOfDay",
                                  :value_script => 1},
                  :facet_filter => {:term => {:phone => phones}}
                  }
      end
    end
    counts = Hash.new(0)
    results.facets["time_of_day"]["entries"].each {|x| counts.merge({x.key => x.count})}
    counts
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
