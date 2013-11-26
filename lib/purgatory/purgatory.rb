require 'purgatory/purgatory_module'

class Purgatory < ActiveRecord::Base
  belongs_to :soul, polymorphic: true, autosave: false
  belongs_to :requester, class_name: PurgatoryModule.configuration.user_class_name
  belongs_to :approver, class_name: PurgatoryModule.configuration.user_class_name
  before_create :store_changes
  before_create :destroy_pending_with_same_soul

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
    @soul ||= (super || (sti_class || soul_type).constantize.new)
  end

  def sti_class
    requested_changes['type'].try(:last)
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

  def self.pending_with_matching_soul(soul)
    pending.where("soul_id IS NOT NULL AND soul_id = ? AND soul_type = ?", soul.id, soul.class.name)
  end

  private

  def store_changes
    self.requested_changes = soul.changes
  end

  def destroy_pending_with_same_soul
    Purgatory.pending_with_matching_soul(soul).destroy_all
  end
end
