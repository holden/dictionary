class BotsController < ApplicationController
  before_action :authenticate
  before_action :set_bot, only: [:show, :edit, :update, :destroy]

  def index
    @bots = Bot.all.order(:name)
  end

  def show
    @influences = @bot.bot_influences.includes(:person)
  end

  def new
    @bot = Bot.new
  end

  def create
    @bot = Bot.new(bot_params)

    if @bot.save
      redirect_to @bot, notice: "Bot was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @bot.update(bot_params)
      redirect_to @bot, notice: "Bot was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bot.destroy
    redirect_to bots_url, notice: "Bot was successfully deleted."
  end

  private

  def set_bot
    @bot = Bot.find(params[:id])
  end

  def bot_params
    params.require(:bot).permit(:name, :personality, :base_model, :voter_weight, :curation_focus)
  end
end 