require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_phone_number(phone_number)
  
  #If the phone number is less than 10 digits, assume that it is a bad number[done]
  #If the phone number is 10 digits, assume that it is good[done]
  #If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits[done]
  #If the phone number is 11 digits and the first number is not 1, then it is a bad number[done]
  #If the phone number is more than 11 digits, assume that it is a bad number[done]
  
  if phone_number.length < 10
    phone_number = nil
  elsif phone_number.length > 11
    phone_number = nil
  elsif phone_number.length == 11 && phone_number[0] != '1'
    phone_number = nil
  elsif phone_number.length == 11 && phone_number[0] == '1' 
    phone_number = phone_number[1..10]
  elsif phone_number.length == 10
    phone_number
  end

  phone_number
end

def peak_registration_hours_and_dates
  
  contents = CSV.open(
  'lib/event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

  # '11/12/08 10:47'
  
  days_array = []
  hour_array = []

  contents.each do |row|
    regDate = row[:regdate].split(" ")

    date = Time.strptime(regDate[0], '%m/%d/%y')
    hours = regDate[1][0..1].to_i
    minutes = regDate[1][3..4].to_i

    full_registration_date = Time.new(date.year, date.month, date.day, hours, minutes)

    hour_array.push(full_registration_date.hour)
    days_array.push(full_registration_date.strftime('%A'))
  end

  distribution_hours = hour_array.tally.sort_by(&:last).reverse.to_h

  distribution_days = days_array.tally.sort_by(&:last).reverse.to_h


  puts "------------Hour Distribution-----------\n \n #{distribution_hours}"

  puts "------------Top 3 Hours-----------------\n \n"

  distribution_hours.first(3).each_with_index do |(k, v), i| 
    i += 1
    puts "#{i}) Hour: #{k}:00 with #{v} registrations"
  end

  puts "------------Day Distribution-----------\n \n #{distribution_days}"

  puts "------------Top 3 Hours-----------------\n \n"

  distribution_days.first(3).each_with_index do |(k, v), i| 
    i += 1
    puts "#{i}) Day: #{k} with #{v} registrations"
  end
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

=begin
puts 'EventManager initialized.'

contents = CSV.open(
  'lib/event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
=end 

peak_registration_hours_and_dates
