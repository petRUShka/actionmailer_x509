require 'actionmailer_x509'
require 'rails'
module ActionMailerX509
  class Railtie < Rails::Railtie
    rake_tasks do
      load "tasks/actionmailer_x509.rake"
      load "tasks/tiny_performance_test.rake"
    end
  end
end
