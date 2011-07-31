# Copyright (c) 2007 Fabien Penso <fabien.penso@conovae.com>
#
# actionmailer_x509 is a rails plugin to allow X509 outgoing mail to be X509
# signed.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Berkeley nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
require 'actionmailer_x509/railtie' if defined?(Rails)
require "openssl"

module ActionMailer #:nodoc:
  class Base #:nodoc:
    @@default_x509_sign = false
    @@default_x509_sign_cert = nil
    @@default_x509_sign_key = nil
    @@default_x509_sign_passphrase = nil

    @@default_x509_crypt = false
    @@default_x509_crypt_cert = nil
    @@default_x509_crypt_cipher = "des"

    @@default_x509_sign_and_crypt_method = :smime

    # Should we sign the outgoing mail?
    adv_attr_accessor :x509_sign

    # Should we crypt the outgoing mail?
    adv_attr_accessor :x509_crypt

    # Which certificate will be used for signing.
    adv_attr_accessor :x509_sign_cert

    # Which private key will be used for signing.
    adv_attr_accessor :x509_sign_key

    # Which certificate will be used for crypting.
    adv_attr_accessor :x509_crypt_cert

    # Which encryption algorithm will be used for crypting.
    adv_attr_accessor :x509_crypt_cipher

    # Which signing method is used. NOTE: For later, if needed.
    adv_attr_accessor :x509_sign_and_crypt_method

    # Passphrase for the sign key, if needed.
    adv_attr_accessor :x509_sign_passphrase

    # We replace the initialize methods and run a new method if signing or crypting is required
    def initialize_with_sign_and_crypt(method_name, *parameters)
      mail = initialize_without_sign_and_crypt(method_name, *parameters)

      x509_initvar()

      # If we need to sign the outgoing mail.
      if should_sign? or should_crypt?
        if logger
          logger.debug("actionmailer_x509: We should sign and\or crypt the mail with #{@x509_sign_and_crypt_method} method.")
        end
        __send__("x509_#{@x509_sign_and_crypt_method}", mail)
      end

    end
    alias_method_chain :initialize, :sign_and_crypt

    # X509 SMIME signing and\or crypting
    def x509_smime(mail)
      if logger
        logger.debug("actionmailer_x509: X509 SMIME signing with cert #{@x509_cert} and key #{@x509_key}") if should_sign?
        logger.debug("actionmailer_x509: X509 SMIME crypt with cert #{@x509_cert}") if should_crypt?
      end

      # We should set content_id, otherwise Mail will set content_id after signing and will broke sign
      mail.content_id ||= nil
      mail.parts.each {|p| p.content_id ||= nil}

      # We can remove the headers from the older mail we encapsulate.
      # Leaving allows to have the headers signed too within the encapsulated
      # email, but MUAs make no use of them... :(
      #
      # mail.subject = nil
      # mail.to = nil
      # mail.cc = nil
      # mail.from = nil
      # mail.date = nil
      # headers.each { |k, v| mail[k] = nil }
      # mail['Content-Type'] = 'text/plain'
      # mail.mime_version = nil

      # We load certificate and private key
      if should_sign?
        sign_cert = OpenSSL::X509::Certificate.new( File::read(@x509_sign_cert) )
        sign_prv_key = OpenSSL::PKey::RSA.new( File::read(@x509_sign_key), @x509_sign_passphrase)
      end

      if should_crypt?
        crypt_cert = OpenSSL::X509::Certificate.new( File::read(@x509_crypt_cert) )
        cipher = OpenSSL::Cipher.new(@x509_crypt_cipher)
      end

#      begin
        # Sign and crypt the mail

        # NOTE: the one following line is the slowest part of this code, signing is sloooow
        p7 = mail.encoded
        p7 = OpenSSL::PKCS7.sign(sign_cert,sign_prv_key, p7, [], OpenSSL::PKCS7::DETACHED) if should_sign?
        p7 = OpenSSL::PKCS7.encrypt([crypt_cert], (should_sign? ? OpenSSL::PKCS7::write_smime(p7) : p7), cipher, nil) if should_crypt?
        smime0 = OpenSSL::PKCS7::write_smime(p7)

        # Adding the signature part to the older mail
        newm = Mail.new(smime0)

        # We need to overwrite the content-type of the mail so MUA notices this is a signed mail
#        newm.content_type = 'multipart/signed; protocol="application/x-pkcs7-signature"; micalg=sha1; '
         newm.delivery_method(mail.delivery_method.class, mail.delivery_method.settings)
         newm.subject = mail.subject
         newm.to = mail.to
         newm.cc = mail.cc
         newm.from = mail.from
         newm.mime_version = mail.mime_version
         newm.date = mail.date
#        newm.body = "This is an S/MIME signed message\n"
#        headers.each { |k, v| m[k] = v } # that does nothing in general

        # NOTE: We can not use this as we need a B64 encoded signature, and no
        # methods provides it within the Ruby OpenSSL library... :(
        #
        # We add the signature
        # signature = Mail.new
        # signature.mime_version = '1.0'
        # signature['Content-Type'] = 'application/x-pkcs7-mime; smime-type=signed-data; name="smime.p7m"'
        # signature['Content-Transfer-Encoding'] = 'base64'
        # signature['Content-Disposition']  = 'attachment; filename="smime.p7m"'
        # signature.body = p7sign.to_s
        # newm.parts << signature

        @_message = newm
#      rescue Exception => detail
#        logger.error("Error while SMIME signing and\or crypting the mail : #{detail}")
#      end

      ## logger.debug("x509_sign_smime, resulted email\n-------------( test X509 )----------\n#{m.encoded}\n-------------( test X509 )----------")

    end

    protected

    # Shall we sign the mail?
    def should_sign?
      @should_sign ||= __should_sign?
    end

    def __should_sign?
      if @x509_sign == true
        if not @x509_sign_cert.nil? and not @x509_sign_key.nil?
          return true
        else
          logger.info "X509 signing required, but no certificate and key files configured"
        end
      end
      return false
    end

    # Shall we crypt the mail?
    def should_crypt?
      @should_crypt ||= __should_crypt?
    end

    def __should_crypt?
      if @x509_crypt == true
        if not @x509_crypt_cert.nil?
          return true
        else
          logger.info "X509 crypting required, but no certificate file configured"
        end
      end
      return false
    end

    # Initiate from the default class attributes
    def x509_initvar
      @x509_sign_and_crypt_method ||= @@default_x509_sign_and_crypt_method
      @x509_sign                  ||= @@default_x509_sign
      @x509_crypt                 ||= @@default_x509_crypt
      @x509_crypt_cert            ||= @@default_x509_crypt_cert
      @x509_crypt_cipher          ||= @@default_x509_crypt_cipher
      @x509_sign_cert             ||= @@default_x509_sign_cert
      @x509_key                   ||= @@default_x509_sign_key
      @x509_sign_passphrase       ||= @@default_x509_sign_passphrase
    end
  end
end
