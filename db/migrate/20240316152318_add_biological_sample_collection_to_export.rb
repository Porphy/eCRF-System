class AddBiologicalSampleCollectionToExport < ActiveRecord::Migration
  def change
    5.times do |index|
      add_column :export_caches, "biological_sample_collection_#{index}", :text
    end
  end
end
