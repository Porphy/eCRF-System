class AddReserachCompletionToExport < ActiveRecord::Migration
  def change
    add_column :export_caches, :reserach_completion, :text
  end
end
