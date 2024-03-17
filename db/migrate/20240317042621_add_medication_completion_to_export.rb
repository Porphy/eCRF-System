class AddMedicationCompletionToExport < ActiveRecord::Migration
  def change
    add_column :export_caches, :medication_completion, :text
  end
end
