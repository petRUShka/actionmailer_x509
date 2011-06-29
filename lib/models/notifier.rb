class Notifier < ActionMailer::Base #:nodoc:

#  self.template_root = "#{File.dirname(__FILE__)}/../views/"
  self.prepend_view_path("#{File.dirname(__FILE__)}/../views/")

  def fufu(email, from, subject = "Empty subject")
    mail(:to => email, :subject => subject, :from => from)
  end

  def fufusigned(email, from ,
    subject = "Empty subject for signed",
    cert = "#{File.dirname(__FILE__)}/../certs/server.crt",
    key = "#{File.dirname(__FILE__)}/../certs/server.key")

    x509_sign   true
    x509_cert   cert
    x509_key    key
    x509_passphrase  "demo"

    mail(:subject => subject, :to => email, :from => from) do |format|
      format.text {render 'fufu'}
    end
  end
end
