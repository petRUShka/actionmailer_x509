class Notifier < ActionMailer::Base #:nodoc:

#  self.template_root = "#{File.dirname(__FILE__)}/../views/"
  self.prepend_view_path("#{File.dirname(__FILE__)}/../views/")

  def fufu(email, from, subject = "Empty subject")
    fufu_signed_and_or_crypted(email, from, subject)
  end

  def fufu_signed(email, from ,
    subject = "Empty subject for signed", cert = "#{File.dirname(__FILE__)}/../certs/server.crt",
    key = "#{File.dirname(__FILE__)}/../certs/server.key")

    fufu_signed_and_or_crypted(email, from, subject, { :signed => true }, cert, key)
  end

  def fufu_crypted(email, from ,
    subject = "Empty subject for encrypted")

    fufu_signed_and_or_crypted(email, from, subject, :crypted => true)
  end

  def fufu_signed_and_crypted(email, from ,
    subject = "Empty subject for signed and encrypted")

    fufu_signed_and_or_crypted(email, from, subject, { :signed => true, :crypted => true })
  end

  def fufu_signed_and_or_crypted(email, from ,
    subject = "Empty subject", options = {},
    cert = "#{File.dirname(__FILE__)}/../certs/server.crt",
    key = "#{File.dirname(__FILE__)}/../certs/server.key")

    if options[:crypted]
      x509_crypt            true
      x509_crypt_cert       cert
    end

    if options[:signed]
      x509_sign             true
      x509_sign_cert        cert
      x509_sign_key         key
      x509_sign_passphrase  "demo"
    end

    mail(:subject => subject, :to => email, :from => from) do |format|
      format.text {render 'fufu'}
    end
  end
end
