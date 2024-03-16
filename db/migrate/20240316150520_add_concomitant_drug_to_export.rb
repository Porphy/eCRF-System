class AddConcomitantDrugToExport < ActiveRecord::Migration
  def change
    5.times do |index|
      add_column :export_caches, "concomitant_drug_#{index}", :text
    end
  end
end
