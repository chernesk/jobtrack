class Activity < ApplicationRecord
  belongs_to :opportunity

  enum :kind, { email: "email", call: "call", interview: "interview", note: "note" }, validate: true

  validates :occurred_on, :body, presence: true
end
