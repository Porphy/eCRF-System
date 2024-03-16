class AddRadiationTherapyToExport < ActiveRecord::Migration
  def change
    5.times do |index|
      add_column :export_caches, "radiation_therapy_#{index}", :text
    end
  end
end
