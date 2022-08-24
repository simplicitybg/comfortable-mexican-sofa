# Data only migration to resave all Revisions as JSON, instead of YAML, which is vulnerable to CVE-2022-32224
class UpgradeTo1151 < ActiveRecord::Migration
  def self.up
    Rails.configuration.active_record.yaml_column_permitted_classes = [Symbol]
    ActiveRecord::Base.partial_writes = false
    Comfy::Cms::Revision.serialize :data

    Comfy::Cms::Revision.find_in_batches(batch_size: 20).each do |group|
      group.each do |revision|
        Comfy::Cms::Revision.serialize :data, JSON
        revision.save!
        Comfy::Cms::Revision.serialize :data
      end
    end

    Comfy::Cms::Revision.serialize :data, JSON
    ActiveRecord::Base.partial_writes = true
    Rails.configuration.active_record.yaml_column_permitted_classes = nil
  end
  
  def self.down
  end
end
