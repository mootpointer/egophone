class SearchController < ApplicationController

  def index
    if params[:search]
      @results = Message.search params[:search]
    end
  end
end
