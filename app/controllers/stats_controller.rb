class StatsController < ApplicationController

  def index
    # This code is insanely slow.  
    direction = Person.direction.to_a
    sorted_data = Message.time_of_day.sort.flatten
    @graph_data = []
    sorted_data.each_with_index{|count, index| @graph_data << count if index % 2 != 0}
    
    @most_sent_to = direction.sort{|a,b| b['value']['out'] <=> a['value']['out']}.take(20)
    @most_received_from = direction.sort{|a,b| b['value']['in'] <=> a['value']['in']}.take(20)
    
    @most_sent_words = Message.words(:in) # Person.words.to_a.sort{|a, b| 
          #b['value']['out'] <=> a['value']['out']}.select{|w| w['_id'].length > 3}.take(20)
  end
end
