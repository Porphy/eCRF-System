class AddGroupInformationToExport < ActiveRecord::Migration
  def change
    add_column :export_caches, :group_information, :text
  end
end
