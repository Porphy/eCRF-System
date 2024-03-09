class BloodBiochemistry < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :name, in: BLOODCNAME_OPT
  enumerize :unit, in: BLOODCUNIT_OPT

  belongs_to :basement_assessment


  validates :name,presence: true
  validates :value,presence: true
  validates :sample_date,presence: true

  after_save :set_export_cache

  private 

  def set_export_cache
    begin
      index = patient.blood_biochemistries.index(self)
      _tmp = patient.blood_biochemistries.order('created_at desc')
      _size = _tmp.columns_for_export.size
      cache = ExportCache.find_by(patient_id: patient_id)
      hsh = {}
      Export::EXPORT_LIMIT[model_name.plural.to_sym].times do |i|
        vals = _tmp[i].nil? ?
            Array.new(_size) : _tmp[i].values_for_export
        hsh["#{model_name.singular}_#{i}"] = vals.to_csv(row_sep: nil)
      end
      cache.update(hsh)
    rescue
      
    end
  end

end
