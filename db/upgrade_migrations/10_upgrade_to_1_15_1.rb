# Data only migration to resave all Revisions as JSON, instead of YAML, which is vulnerable to CVE-2022-32224
class UpgradeTo1151 < ActiveRecord::Migration
  def self.up
    Comfy::Cms::Revision.order(:id).find_in_batches(batch_size: 20).each do |group|
      group.each do |revision|
        revision.update_column(:data, YAML.load(revision.read_attribute_before_type_cast(:data)))
      end
    end
  end
  
  def self.down
  end
end
