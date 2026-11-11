class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :edit, :update, :destroy]

  def index
    @conversations = Conversation.order(created_at: :desc)
  end

  def show
    @analytics_engine = AnalyticsEngine.new(@conversation)
    @summary_stats = @analytics_engine.summary_stats
    @recent_messages = @conversation.messages.reverse_chronological.limit(50)
  end

  def new
    @conversation = Conversation.new
  end

  def create
    @conversation = Conversation.new(conversation_params)

    if @conversation.save
      redirect_to @conversation, notice: "Conversation created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @conversation.update(conversation_params)
      redirect_to @conversation, notice: "Conversation updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_url, notice: "Conversation deleted successfully."
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end

  def conversation_params
    params.require(:conversation).permit(:title, :description)
  end
end
