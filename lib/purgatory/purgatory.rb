class Purgatory < ActiveRecord::Base
  attr_accessible :requester, :soul

  belongs_to :soul, polymorphic: true, autosave: false
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User'
  before_create :store_changes

  validates :soul_type, presence: true

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

  def soul
    super || soul_type.constantize.new
  end

  def approve!(approver = nil)
    return false if approved?
    changes = changes_hash

    if soul.update_attributes(changes.update(changes){|k,v| v.last}, without_protection: true)
      self.approver = approver
      self.approved_at = Time.now
      save
      return true
    end
    false
  end

  private

  def store_changes
    self.changes_json = ActiveSupport::JSON.encode(soul.changes)
  end
end
