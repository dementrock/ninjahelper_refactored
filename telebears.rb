require 'mechanize'
require 'yaml'

def within_telebears(action)
  config = YAML::load(File.open('config.yaml').read)
  agent = Mechanize.new
  telebears_url = 'https://telebears.berkeley.edu/'
  puts "entering telebears web @page..."
  @page = agent.get telebears_url
  login_form = @page.form_with :id => 'loginForm'
  login_form['username'] = config['username'] 
  login_form['password'] = config['password']
  puts "login..."
  @page = login_form.submit
  action.call(@page)
  puts "logging out telebears..."
  @page = @page.link_with(:href => /logout/).click
  puts "logging out cas..."
  @page = @page.link_with(:href => /logout/).click
end

def drop_class(ccn)
    puts "dropping #{ccn}"
    puts "entering enrollment @page..."
    @page = @page.link_with(:href => /enrollment/).click
    puts "entering drop class @page..."
    @page = @page.link_with(:href => /drop_class/).click
    drop_form = @page.form_with :name => 'FIND'
    drop_form.radiobutton_with(:value => ccn).check
    puts "selecting class to drop..."
    @page = drop_form.click_button(drop_form.button_with(:value => 'Continue'))
    confirm_form = @page.forms.first
    puts "confirming..."
    @page = confirm_form.click_button(confirm_form.button_with(:value => 'Continue'))
end

def add_class(hash)
    ccn = hash.is_a?(Hash) ? hash[:ccn] : hash
    puts ccn
    puts "adding #{ccn}"
    puts "entering enrollment @page..."
    @page = @page.link_with(:href => /enrollment/).click
    puts "entering add class @page..."
    @page = @page.link_with(:href => /add_class/).click
    add_form = @page.form_with :name => 'FIND'
    add_form["_InField1"] = ccn
    @page = add_form.click_button(add_form.button_with(:value => 'Continue'))
    puts @page.inspect
    @page = hash[:with_section].each {|ccn| add_section ccn} if not @page.forms.first.button_with value: 'Confirm'
    confirm_form = @page.forms.first
    puts "confirming..."
    @page = confirm_form.click_button(confirm_form.button_with(:value => 'Confirm'))
end

def add_section(ccn)
    drop_form = @page.form_with name: 'FIND'
    drop_form.radiobutton_with(value: ccn).check
    puts "seleteced intended section"
    @page = drop_form.click_button(drop_form.button_with(value: 'Continue'))
end

@tasks = Proc.new do #lists of tasks in semi-natural language
  #drop_class('87636')
  # add_class '87636'
  # drop_class '25099'
  add_class ccn: '25099', with_section: ['25111']
end

def main
  puts 'starting sequence of tasks'
  within_telebears @tasks
  puts 'ending'
end

main

