Gem::Specification.new do |s|
  s.name = 'old_school'
  s.version = '0.0.4'
  s.date = '2013-01-10'
  s.summary = 'Ruby Gem for a Powerful SIS'
  s.description = 'Provides an interface to work with a Powerful SIS REST API'
  s.authors = ['kaiged']
  s.email = 'kaiged@gmail.com'
  s.files = ['lib/old_school.rb','lib/old_school/api/old_school_api.rb','lib/old_school/api/old_school_api_utils.rb']
  s.homepage = 'https://github.com/kaiged/old_school'

  s.add_dependency 'typhoeus', '>= 0.6.7'
  s.add_dependency 'json', '>1.8.1'
end
