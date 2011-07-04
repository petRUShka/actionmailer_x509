require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/../init'

class ActionmailerX509Test < Test::Unit::TestCase #:nodoc:

  # If we want to sign a message, verify a signature is attached
  def test_signed
    mail = Notifier.fufusigned("<destination@foobar.com>", "<demo@foobar.com>")

    found = false
    for part in mail.parts do
      if part.content_type =~ /application\/x-pkcs7-signature/
        found = true
        break
      end
    end
    assert_equal found, true

    require 'tempfile'

    tf = Tempfile.new('actionmailer_x509')
    tf.write mail.encoded
    tf.flush

    comm = "openssl smime -verify -in #{tf.path} -CAfile #{File.dirname(__FILE__)}/../lib/certs/ca.crt 2>&1"

    success = false
    output = IO.popen(comm)
    while output.gets do
      if $_ =~ /^Verification successful/
        success = true
      end
    end
    assert_equal(success, true)

  end

  # If we want no signature, verify not signature is attached to the mail
  def test_not_signed
    mail = Notifier.fufu("<destination@foobar.com>", "<demo@foobar.com>")

    found = false
    for part in mail.parts do
      puts part.content_type
      if part.content_type =~ /application\/x-pkcs7-signature/
        found = true
        break
      end
    end
    assert_equal found, false
  end

  # If we want to sign a message but no certificate is on the filesystem
  def test_signed_with_no_certs
    crashed = false
    begin
      mail = Notifier.fufusigned("<destination@foobar.com>", "<demo@foobar.com>", "", "/tmp/doesnotexist")
    rescue Errno::ENOENT => detail
      crashed = true
    end

    assert_equal(crashed, true)
  end

  # If we want to sign a message but incorrect certificate is given
  def test_signed_incorrect_certs
    crashed = false
    begin
      mail = Notifier.fufusigned("<destination@foobar.com>", "<demo@foobar.com>", "", "#{File.dirname(__FILE__)}/../lib/certs/server.key")
    rescue OpenSSL::X509::CertificateError => detail
      crashed = true
    end
    assert_equal(crashed, true)
  end
end
