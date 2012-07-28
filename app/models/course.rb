require 'open-uri'

class Course
  include Mongoid::Document
  include Mongoid::Timestamps

  field :ccn, type: String

  # fields related to enrollment information
  field :enroll_limit, type: Integer, default: 0
  field :current_enroll, type: Integer, default: 0
  field :waitlist_limit, type: Integer, default: 0
  field :current_waitlist, type: Integer, default: 0
  field :prev_info, type: Hash, default: {}
  field :is_waitlist_used, type: Boolean, default: false
  field :is_section_full, type: Boolean, default: false
  field :is_all_full, type: Boolean, default: false
  field :is_first_time, type: Boolean, default: true
  field :is_valid, type: Boolean, default: true

  has_and_belongs_to_many :watchers, class_name: "User", inverse_of: :watched_courses, autosave: true

  validates_presence_of :ccn
  validates_uniqueness_of :ccn
  validate :ccn_correct_format

  def ccn_valid?
    if self.is_first_time
      update_enrollment_info
    end
    self.is_valid
  end
      
  def ccn_correct_format
    if ccn !~ /\d{5}/
      errors.add(:ccn, 'must have exactly 5 digits')
    end
  end

  def enrollment_url
    "http://infobears.berkeley.edu:3400/osc/?_InField1=RESTRIC&_InField2=#{ccn}&_InField3=#{Rails.application.config.current_term}"
  end

  def full_enrollment_info
    {
      enroll_limit: enroll_limit,
      current_enroll: current_enroll,
      waitlist_limit: waitlist_limit,
      current_waitlist: current_waitlist,
      is_waitlist_used: is_waitlist_used,
      is_section_full: is_section_full,
      is_all_full: is_all_full,
      is_valid: is_valid,
    }
  end

  def update_enrollment_info(options={})
    if not self.is_valid
      return
    end
    page = Nokogiri::HTML(open(enrollment_url))
    blockquote = page.xpath("//blockquote").first
    if blockquote.nil?
      self.is_valid = false
      self.save
      return
    end
    raw_description = page.xpath("//blockquote").first.text
    self.prev_info = self.full_enrollment_info
    self.is_waitlist_used = !(raw_description =~ /does not use a Waiting List/i)
    numbers = raw_description.scan(/\d+/).map(&:to_i)

    case numbers.length
    when 4
      self.current_enroll, self.enroll_limit, self.current_waitlist, self.waitlist_limit = numbers
    when 0
      self.is_all_full = true
    when 2
      if self.is_waitlist_used
        self.current_waitlist, self.waitlist_limit = numbers
        self.is_section_full = true
      else
        self.current_enroll, self.enroll_limit = numbers
      end
    else
      Rails.logger.info "This is really weird orz... (enrollment information for #{ccn}): #{raw_description}"
    end

    if self.waitlist_limit == 0
      self.is_waitlist_used = false # actually false
    end
    if self.is_first_time
      self.prev_info = self.full_enrollment_info
    end
    self.is_first_time = false
    self.save

  end

  def enrollment_diff
    full_enrollment_info.diff(prev_info)
  end

end
