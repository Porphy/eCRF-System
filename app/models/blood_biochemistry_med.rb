class BloodBiochemistryMed < ActiveRecord::Base
  extend Enumerize
  include Constant
  include Export

  enumerize :name, in: BLOODCNAME_OPT
  enumerize :unit, in: BLOODCUNIT_OPT

  belongs_to :medication_completion


  validates :name,presence: true
  validates :value,presence: true
  validates :sample_date,presence: true

end
