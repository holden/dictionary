class BotInfluencesController < ApplicationController
  before_action :authenticate
  before_action :set_bot

  def new
    @influence = @bot.bot_influences.build
  end

  def create
    @influence = @bot.bot_influences.build(influence_params)

    if @influence.save
      redirect_to @bot, notice: "Influence was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @influence = @bot.bot_influences.find(params[:id])
    @influence.destroy
    redirect_to @bot, notice: "Influence was successfully removed."
  end

  private

  def set_bot
    @bot = Bot.find(params[:bot_id])
  end

  def influence_params
    params.require(:bot_influence).permit(:person_id, :influence_weight)
  end
end 