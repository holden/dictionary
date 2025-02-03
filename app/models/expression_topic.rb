class ExpressionTopic < ApplicationRecord
  belongs_to :expression
  belongs_to :topic

  validates :expression_id, uniqueness: { scope: :topic_id }
end 