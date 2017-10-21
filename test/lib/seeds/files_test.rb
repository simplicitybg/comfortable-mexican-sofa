require_relative '../../test_helper'

class SeedsFilesTest < ActiveSupport::TestCase

  def test_creation
    Comfy::Cms::File.delete_all

    # need to have categories present before linking
    site = comfy_cms_sites(:default)
    site.categories.create!(categorized_type: 'Comfy::Cms::File', label: 'category_a')
    site.categories.create!(categorized_type: 'Comfy::Cms::File', label: 'category_b')

    assert_difference 'Comfy::Cms::File.count' do
      ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site').import!
      assert file = Comfy::Cms::File.last

      assert_equal 'Fixture File',        file.label
      assert_equal 'default.jpg',          file.attachment.filename.to_s
      assert_equal 'Fixture Description', file.description

      assert_equal 2, file.categories.count
      assert_equal ['category_a', 'category_b'], file.categories.map{|c| c.label}
    end
  end

  def test_update
    file = comfy_cms_files(:default)
    file.update_column(:updated_at, 10.years.ago)
    assert_equal 'default.jpg',          file.attachment.filename.to_s
    assert_equal 'default file',        file.label
    assert_equal 'default description', file.description

    assert_no_difference 'Comfy::Cms::Snippet.count' do
      ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site').import!
      file.reload
      assert_equal 'default.jpg',         file.attachment.filename.to_s
      assert_equal 'Fixture File',        file.label
      assert_equal 'Fixture Description', file.description
    end
  end

  def test_update_ignore
    file = comfy_cms_files(:default)
    file_path = File.join(ComfortableMexicanSofa.config.seeds_path, 'sample-site', 'files', 'default.jpg')
    attr_path = File.join(ComfortableMexicanSofa.config.seeds_path, 'sample-site', 'files', '_default.jpg.yml')

    assert file.updated_at >= File.mtime(file_path)
    assert file.updated_at >= File.mtime(attr_path)

    ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site').import!
    file.reload
    assert_equal 'default.jpg',         file.attachment.filename.to_s
    assert_equal 'default file',        file.label
    assert_equal 'default description', file.description
  end

  def test_update_force
    file = comfy_cms_files(:default)
    ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site').import!
    file.reload
    assert_equal 'default file', file.label

    ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site', :forced).import!
    file.reload
    assert_equal 'Fixture File', file.label
  end

  def test_delete
    old_file = comfy_cms_files(:default)
    active_storage_blobs(:default).update_column(:filename, 'old')

    assert_no_difference 'Comfy::Cms::File.count' do
      ComfortableMexicanSofa::Seeds::File::Importer.new('sample-site', 'default-site').import!
      assert file = Comfy::Cms::File.last
      assert_equal 'default.jpg',         file.attachment.filename.to_s
      assert_equal 'Fixture File',        file.label
      assert_equal 'Fixture Description', file.description

      assert Comfy::Cms::File.where(id: old_file.id).blank?
    end
  end

  def test_export
    host_path = File.join(ComfortableMexicanSofa.config.seeds_path, 'test-site')
    attr_path = File.join(host_path, 'files/_default.jpg.yml')
    file_path = File.join(host_path, 'files/default.jpg')

    # We don't have saved file, so lets fake that
    ActiveStorage::Blob.any_instance.stubs(:download).returns(
      File.read(File.join(Rails.root, 'db/cms_seeds/sample-site/files/default.jpg'))
    )

    ComfortableMexicanSofa::Seeds::File::Exporter.new('default-site', 'test-site').export!

    assert File.exist?(attr_path)
    assert File.exist?(file_path)
    assert_equal ({
      'label'         => 'default file',
      'description'   => 'default description',
      'categories'    => ['Default'],
      "content_type"  => "image/jpg"
    }), YAML.load_file(attr_path)

  ensure
    FileUtils.rm_rf(host_path)
  end
end
