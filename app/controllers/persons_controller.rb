class PersonsController < ApplicationController
  def show
    @person = Person.where(:name => params[:id]).first
    render :json => @person.stats
  end
end