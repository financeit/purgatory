class Purgatory < ActiveRecord::Base
  attr_accessible :requester, :soul

  belongs_to :soul, polymorphic: true, autosave: false
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User'
  before_create :store_changes

  validates :soul_type, :requester_id, presence: true

  scope :pending, conditions: { approved_at: nil }
  scope :approved, conditions: ["approved_at IS NOT NULL"]

  def approved?
    approved_at.present?
  end

  def pending?
    approved_at.nil?
  end

  def changes_hash
    ActiveSupport::JSON.decode(changes_json)
  end

  def approve!(approver)
    return if approved_at.present?
    changes = changes_hash

    soul = soul_type.constantize.new unless soul.present?

    if soul.update_attributes(changes.update(changes){|k,v| v.last}, without_protection: true)
      self.approver = approver
      self.approved_at = Time.now
      save
    end
  end

  private

  def store_changes
    self.changes_json = ActiveSupport::JSON.encode(soul.changes)
  end
end
