class AddDeathRecordToExport < ActiveRecord::Migration
  def change
    add_column :export_caches, :death_record, :text
  end
end
