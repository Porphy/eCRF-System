class AddBasementAssessmentToExport < ActiveRecord::Migration
  def change
    add_column :export_caches, :basement_assessment, :text
  end
end
