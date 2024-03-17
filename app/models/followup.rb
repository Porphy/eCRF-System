class Followup < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :cause_of_death, in:DEATH_OPT

  belongs_to :patient


  after_create :set_followup_monitor
  before_destroy :roll_backMonitor

  after_save :set_export_cache

  # validates :date_of_visit,presence: true


  def set_followup_monitor
    if self.id==self.patient.followups.last.id
      self.patient.followup_monitor.update(last_followup_date:self.date_of_visit)
    end

  end

  def roll_backMonitor
    if self.patient.followups.size() >1
      self.patient.followup_monitor.update(last_followup_date:self.patient.followups.last(2).first.date_of_visit)
    end
  end

  def set_export_cache
    begin
      index = patient.followups.index(self)
      _tmp = patient.followups.order('created_at desc')
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
