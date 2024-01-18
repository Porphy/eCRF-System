class CreateExportCaches < ActiveRecord::Migration
  def change
    create_table :export_caches do |t|
      t.belongs_to :patient, index: true

      [:patient].each do |col|
        t.text col
      end

      t.timestamps null: false
    end
  end
end
