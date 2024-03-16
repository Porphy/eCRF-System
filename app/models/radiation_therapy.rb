class RadiationTherapy < ActiveRecord::Base
  extend Enumerize
  include Constant
  include FlagShihTzu
  include Export

  enumerize :therapy_type, in: THERAPYTYPE_OPT

  has_flags 1=>:chest_wall,2=>:axilla,3=>:collarbone,4=>:internal_breast,
            5=>:whole_breast,6=>:part_of_breast,7=>:others,8=>:unkown, column:"radiotherapy_site"

  belongs_to :patient
  after_save :set_export_cache

  def set_export_cache
    begin
      index = patient.radiation_therapies.index(self)
      _tmp = patient.radiation_therapies.order('created_at desc')
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
