require 'purgatory/purgatory_module'

class Purgatory < ActiveRecord::Base
  belongs_to :soul, polymorphic: true, autosave: false
  belongs_to :requester, class_name: PurgatoryModule.configuration.user_class_name
  belongs_to :approver, class_name: PurgatoryModule.configuration.user_class_name
  before_create :store_changes
  before_create :destroy_pending_with_same_soul

  validates :soul_type, presence: true

  serialize :requested_changes
  serialize :attr_accessor_fields
  serialize :performable_method

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
    read_attribute(:requested_changes)['type'].try(:last)
  end

  # Deserialize encrypted attributes on read
  def requested_changes
    alter(super, :deserialize)
  end

  def soul_with_changes
    requested_changes.each{|k,v| soul.send(:write_attribute, k, v[1])} if requested_changes
    attr_accessor_fields.each{|k,v| soul.instance_variable_set(k, v)} if attr_accessor_fields
    soul
  end

  def approve!(approver = nil)
    return false if approved?

    success = nil
    self.with_lock do
      unless approved?
        success = soul_with_changes.save
        if performable_method.present? && success
          performable_method[:kwargs] ||= {}
          success = soul.send(performable_method[:method], *performable_method[:args], **performable_method[:kwargs])
        end

        if success
          self.approver = approver
          self.approved_at = Time.now
          self.soul_id = soul.id
          save
        end
      end
    end

    success
  end

  def self.pending_with_matching_soul(soul)
    pending.where("soul_id IS NOT NULL AND soul_id = ? AND soul_type = ?", soul.id, soul.class.base_class.name)
  end

  private

  def store_changes
    # Store the ciphertext of encrypted attributes
    self.requested_changes = alter(soul.changes, :serialize)
  end

  def alter(changes, serialization_method)
    encrypted_attr_changes = changes.slice(*soul.class.encrypted_attributes)
    return changes if encrypted_attr_changes.empty?

    altered = encrypted_attr_changes.each_with_object({}) do |(attribute_name, attr_changes), hsh|
      type = soul.class.type_for_attribute(attribute_name)
      hsh[attribute_name] = attr_changes.map { |value| type.send(serialization_method, value) }
    end

    changes.merge(altered)
  end

  def destroy_pending_with_same_soul
    Purgatory.pending_with_matching_soul(soul).destroy_all
  end
end
