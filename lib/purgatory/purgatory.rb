class Purgatory < ActiveRecord::Base
  belongs_to :soul, polymorphic: true, autosave: false
  belongs_to :requester, class_name: 'User'
  belongs_to :approver, class_name: 'User'
  before_create :store_changes

  validates :soul_type, presence: true

  serialize :requested_changes

  def self.pending
    where(approved_at: nil)
  end
  
  def self.approved
    where ["approved_at IS NOT NULL"]
  end

  def approved?
    approved_at.present?
  end

  def pending?
    approved_at.nil?
  end

  def soul
    @soul ||= (super || soul_type.constantize.new)
  end

  def approve!(approver = nil)
    return false if approved?
    requested_changes.each{|k,v| soul.send "#{k}=", v[1]}
    if soul.save
      self.approver = approver
      self.approved_at = Time.now
      save
      return true
    end
    false
  end

  private

  def store_changes
    self.requested_changes = soul.changes
  end
end
