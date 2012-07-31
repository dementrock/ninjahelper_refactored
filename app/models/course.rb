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
  field :is_waitlist_used, type: Boolean, default: false
  field :is_section_full, type: Boolean, default: false
  field :is_all_full, type: Boolean, default: false
  field :is_first_time, type: Boolean, default: true
  field :is_valid, type: Boolean, default: true
  field :is_supported, type: Boolean, default: true

  has_and_belongs_to_many :watchers, class_name: "User", inverse_of: :watched_courses, autosave: true

  attr_accessible :enroll_limit, :current_enroll, :waitlist_limit, :current_waitlist,
                  :is_waitlist_used, :is_section_full, :is_all_full, :is_first_time,
                  :is_valid, :is_supported, :ccn

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
    if ccn !~ /^\d{5}$/
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
    }
  end

  def update_enrollment_info(options={})
    return {} if !self.is_valid && !self.is_first_time
    return {} if !self.is_supported && !self.is_first_time
    begin
      page = Nokogiri::HTML(open(enrollment_url))
    rescue Exception => e
      Rails.logger.info e.message
      Rails.logger.info e.backtrace.inspect
      return {}
    end
    if page.text =~ /busy now/mi
      Rails.logger.info "All lines busy when trying to update: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end
    if page.text =~ /currently unavailable/mi
      Rails.logger.info "system unavailable when trying to update: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end
    if page.text =~ /was not found/mi
      update_attributes!(
        is_valid: false,
      )
      Rails.logger.info "Invalid course: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end
    if not page.text =~ /enrollment information/mi # cannot monitor on the separated page; no info displayed
      update_attributes!(
        is_supported: false,
      )
      Rails.logger.info "Unsupported course: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end
    blockquote = page.xpath("//blockquote").first
    if blockquote.nil?
      update_attributes!(
        is_supported: false,
        is_valid: false, # might change this in the future depending on what it actually looks like
      )
      Rails.logger.info "Unsupported course: #{as_document}"
      Rails.logger.info "page: #{page.text}"
      return {}
    end

    _current_enroll = self.current_enroll || 0
    _enroll_limit = self.enroll_limit || 0
    _current_waitlist = self.current_waitlist || 0
    _waitlist_limit = self.waitlist_limit || 0
    _is_waitlist_used = self.is_waitlist_used || false
    _is_section_full = self.is_section_full || false
    _is_all_full = self.is_all_full || false
    
    raw_description = page.xpath("//blockquote").first.text

    prev_info = self.full_enrollment_info # store prev info for later comparison

    _is_waitlist_used = !(raw_description =~ /does not use a Waiting List/i)
    numbers = raw_description.scan(/\d+/).map(&:to_i)

    Rails.logger.info "Number #{numbers} parsed from description #{raw_description}"

    case numbers.length
    when 4
      _current_enroll, _enroll_limit, _current_waitlist, _waitlist_limit = numbers
    when 0
      _is_all_full = true
    when 2
      if _is_waitlist_used
        _current_waitlist, _waitlist_limit = numbers
        _is_section_full = true
      else
        _current_enroll, _enroll_limit = numbers
      end
    else
      Rails.logger.info "This is really weird orz... (enrollment information for #{ccn}): #{raw_description}"
    end

    if _waitlist_limit == 0
      _is_waitlist_used = false # actually false
    end

    update_attributes!(
      current_enroll: _current_enroll,
      enroll_limit: _enroll_limit,
      current_waitlist: _current_waitlist,
      waitlist_limit: _waitlist_limit,
      is_waitlist_used: _is_waitlist_used,
      is_section_full: _is_section_full,
      is_all_full: _is_all_full,
      is_first_time: false,
      is_valid: true,
      is_supported: true,
    )

    Rails.logger.info "prev_info: #{prev_info}\n now_info: #{full_enrollment_info}"

    return diff_message(prev_info, full_enrollment_info)
  end

private

  def _from(cnt)
    if cnt > 0
      "from #{cnt} "
    else
      ""
    end
  end

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
    if diff[:is_waitlist_used] == true
      messages.push "This course has a waitlist now"
    elsif diff[:is_waitlist_used] == false
      messages.push "This course has no waitlist now"
    end
    if diff.has_key? :waitlist_limit
      messages.push "The waitlist limit has changed #{_from(prev_info[:waitlist_limit])}to #{now_info[:waitlist_limit]}"
    end
    if diff.has_key? :current_waitlist
      message = "The current waitlist has changed #{_from(prev_info[:current_waitlist])}to #{now_info[:current_waitlist]}"
      if not diff.has_key? :waitlist_limit
        message += ", with waitlist limit #{now_info[:waitlist_limit]}"
      end
      messages.push message
    end
    if diff.has_key? :enroll_limit
      messages.push "The enrollment limit has changed #{_from(prev_info[:enroll_limit])} to #{now_info[:enroll_limit]}"
    end
    if diff.has_key? :current_enroll
      message = "The current enrollment has changed #{_from(prev_info[:current_enroll])} to #{now_info[:current_enroll]}"
      if not diff.has_key? :enroll_limit
        message += ", with enrollment limit #{now_info[:enroll_limit]}"
      end
      messages.push message
    end

    return messages
  end

end
