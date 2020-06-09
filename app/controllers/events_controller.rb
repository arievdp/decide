class EventsController < ApplicationController
  before_action :set_event, only: [:show]

  def new
    @event = Event.new
    @cuisine_event = CuisineEvent.new
  end

  def create
    @event = Event.new(event_params.except(:cuisine_event_ids))
    if @event.save
      cuisine_event_params(event_params)
    # @save_count == event_params[:cuisine_event_ids].count
      redirect_to event_path(@event)
    else
      render :new
    end
  end

  def show; end

  private

  def cuisine_event_params(event_params)
    @save_count = 0
    event_params[:cuisine_event_ids].each do |id|
        @cuisine_event = CuisineEvent.new
        @cuisine = Cuisine.find(id.to_i)
        @cuisine_event.cuisine = @cuisine
        @cuisine_event.event = @event
        @cuisine_event.save!
        @save_count += 1
    end
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:name, :description, :start_at, cuisine_event_ids: [])
  end
end