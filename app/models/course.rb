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
  #field :prev_info, type: Hash, default: {}
  field :is_waitlist_used, type: Boolean, default: false
  field :is_section_full, type: Boolean, default: false
  field :is_all_full, type: Boolean, default: false
  field :is_first_time, type: Boolean, default: true
  field :is_valid, type: Boolean, default: true
  field :is_supported, type: Boolean, default: true

  has_and_belongs_to_many :watchers, class_name: "User", inverse_of: :watched_courses, autosave: true

  validates_presence_of :ccn
  validates_uniqueness_of :ccn
  validate :ccn_correct_format

  def ccn_valid?
    if self.is_first_time or created_at == updated_at # never updated before
      update_enrollment_info
    end
    self.is_valid
  end

  def supported?
    if self.is_first_time or created_at == updated_at
      update_enrollment_info
    end
    self.is_supported
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
    return {} if not self.is_valid
    return {} if not self.is_supported
    begin
      page = Nokogiri::HTML(open(enrollment_url))
    rescue Exception => e
      Rails.logger.info e.message
      Rails.logger.info e.backtrace.inspect
      return {}
    end
    if page.text =~ /Sorry, all lines are busy now. Please connect later./
      Rails.logger.info "All lines busy when trying to update: #{as_document}"
      return {}
    end
    if page.text =~ /The class you requested was not found/i
      self.is_valid = false
      self.save
      Rails.logger.info "Invalid course: #{as_document}"
      return {}
    end
    if not page.text =~ /enrollment information/i # cannot monitor on the separated page; no info displayed
      self.is_supported = false
      self.save
      Rails.logger.info "Unsupported course: #{as_document}"
      return {}
    end
    blockquote = page.xpath("//blockquote").first
    if blockquote.nil?
      self.is_supported = false
      self.is_valid = false # might change this in the future depending on what it actually looks like
      self.save
      Rails.logger.info "Unsupported course: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end
    raw_description = page.xpath("//blockquote").first.text
    prev_info = self.full_enrollment_info # store prev info for later comparison
    self.is_waitlist_used = !(raw_description =~ /does not use a Waiting List/i)
    numbers = raw_description.scan(/\d+/).map(&:to_i)

    Rails.logger.info "Number #{numbers} parsed from description #{raw_description}"

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
    
    self.is_first_time = false
    self.save

    return diff_message(prev_info, full_enrollment_info)
  end

private
  def diff_message(prev_info, now_info)

    diff = now_info.diff(prev_info)

    if diff.length == 0
      return []
    end

    messages = []

    if diff[:is_all_full] == true
      messages.push "This course is now full"
      return messages
    end
    if diff[:is_all_full] == false
      messages.push "The course is changed from full to (possibly) available."
    end
    if diff[:is_waitlist_used] == true
      messages.push "This course has a waitlist now"
    elsif diff[:is_waitlist_used] == false
      messages.push "This course has no waitlist now"
    end
    if diff.has_key? :waitlist_limit
      messages.push "The waitlist limit has changed from #{prev_info[:waitlist_limit]} to #{now_info[:waitlist_limit]}"
    end
    if diff.has_key? :current_waitlist
      message = "The current waitlist has changed from #{prev_info[:current_waitlist]} to #{now_info[:current_waitlist]}"
      if not diff.has_key? :waitlist_limit
        message += ", with waitlist limit #{now_info[:waitlist_limit]}"
      end
      messages.push message
    end
    if diff.has_key? :enroll_limit
      messages.push "The enrollment limit has changed from #{prev_info[:enroll_limit]} to #{now_info[:enroll_limit]}"
    end
    if diff.has_key? :current_enroll
      message = "The current enrollment has changed from #{prev_info[:current_enroll]} to #{now_info[:current_enroll]}"
      if not diff.has_key? :enroll_limit
        message += ", with enrollment limit #{now_info[:enroll_limit]}"
      end
      messages.push message
    end

    return messages
  end

end
