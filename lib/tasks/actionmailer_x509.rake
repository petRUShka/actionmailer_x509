require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'models/notifier'

namespace :actionmailer_x509 do
  desc "Sending a mail, for test."
  task(:send_test => :environment) do
    if ENV['email'].nil?
      puts "You should call the rake task like\nrake actionmailer_x509:send_test email=yourmail@yourdomain.com\n"
    else
      puts "Note: Please make sure you have configured ActionMailer."
      puts "The mail sent might be stoped by antispam."
      puts "If you wish to verify the signature, please include"
      puts "#{File.dirname(__FILE__)}/../certs/ca.crt"
      puts "as an authority in your MUA. Remove it after your test!!!\n\n"
      puts "Emailing <#{ENV['email']}>"
      Notifier.fufu_signed("#{ENV['email']}", "demo@foobar.com", "Signed mail at #{Time.now.to_s}").deliver
    end
  end


  desc "Performance test."
  task(:performance_test => :environment) do
    require 'benchmark'

    n = 100
    Benchmark.bm do |x|
      x.report("#{n} mails without signature: ") {
        for i in 1..n do
          Notifier.fufu("<destination@foobar.com>", "<demo@foobar.com>")
        end
      }
      x.report("#{n} mails with signature: ") {
        for i in 1..n do
          Notifier.fufu_signed("<destination@foobar.com>", "<demo@foobar.com>")
        end
      }
    end
  end

  desc "Generates a signed mail in a file."
  task(:generate_mail => :environment) do
    mail = Notifier.fufu_signed("<destination@foobar.com>", "<demo@foobar.com>")
    path = ENV['mail']
    path = "tmp/signed_mail.txt" if path.nil?
    File.open(path, "w") do |f|
      f.write mail.encoded
    end
    puts "Signed mail is at #{path}."
    puts "You can use mail=filename as argument to change it." if ENV['mail'].nil?
  end

  desc "Check if signature is valid."
  task(:verify_signature => :environment) do
    require 'tempfile'
    mail = Notifier.fufu_signed("<destination@foobar.com>", "<demo@foobar.com>")

    tf = Tempfile.new('actionmailer_x509')
    tf.write mail.encoded
    tf.flush

    comm = "openssl smime -verify -in #{tf.path} -CAfile #{File.dirname(__FILE__)}/../lib/certs/ca.crt > /dev/null"

    puts "Using openssl command to verify signature..."
    system(comm)

  end
end
