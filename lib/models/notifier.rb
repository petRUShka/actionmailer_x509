class Notifier < ActionMailer::Base #:nodoc:

  self.template_root = "#{File.dirname(__FILE__)}/../views/"

  def fufu(email, from, subject = "Empty subject")
    recipients = email
    from       = from
    subject    = subject
    sent_on    = Time.now
  end

  def fufusigned(email, from , 
                 subject = "Empty subject for signed", 
                 cert = "#{File.dirname(__FILE__)}/../certs/server.crt",
                 key = "#{File.dirname(__FILE__)}/../certs/server.key")
    recipients email
    from       from
    subject    subject
    sent_on    Time.now
    template   "fufu"

    x509_sign   true 
    x509_cert   cert
    x509_key    key
    x509_passphrase  "demo"
  end
end
