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
    @@default_x509_crypt = false # not used, for later.
    @@default_x509_cert = nil
    @@default_x509_key = nil
    @@default_x509_sign_method = :smime
    @@default_x509_crypt_method = :smime # not used, for later.
    @@default_x509_passphrase = nil

    # Should we sign the outgoing mail?
    adv_attr_accessor :x509_sign

    # Should we crypt the outgoing mail?. NOTE: not used yet.
    adv_attr_accessor :x509_crypt

    # Which certificate will be used for signing.
    adv_attr_accessor :x509_cert

    # Which private key will be used for signing.
    adv_attr_accessor :x509_key

    # Which signing method is used. NOTE: For later, if needed.
    adv_attr_accessor :x509_sign_method

    # Which crypting method is used. NOTE: not used yet.
    adv_attr_accessor :x509_crypt_method

    # Passphrase for the key, if needed.
    adv_attr_accessor :x509_passphrase



    # We replace the create! methods and run a new method if signing is required
    def initialize_with_sign(method_name, *parameters)
      mail = initialize_without_sign(method_name, *parameters)

      x509_initvar()

      # If we need to sign the outgoing mail.
      if should_sign?
        if logger
          logger.debug("actionmailer_x509: We should sign the mail with #{@x509_sign_method} method.")
        end
        __send__("x509_sign_#{@x509_sign_method}", mail)
      end

    end
    alias_method_chain :initialize, :sign

    # X509 SMIME signing
    def x509_sign_smime(mail)
      if logger
        logger.debug("actionmailer_x509: X509 SMIME signing with cert #{@x509_cert} and key #{@x509_key}")
      end

      # We create a new mail holding the older mail + signature
#      m = Mail.new
#      m.subject = mail.subject
#      m.to = mail.to
#      m.cc = mail.cc
#      m.from = mail.from
#      m.content_id = mail.content_id
#      m.mime_version = mail.mime_version
#      m.date = mail.date
#      m.body = "This is an S/MIME signed message\n"
#      m.delivery_method(mail.delivery_method.class, mail.delivery_method.settings)
      #      headers.each { |k, v| m[k] = v } # that does nothing in general



      # We should set content_id, otherwise Mail will set content_id after signing and will broke sign
      mail.content_id ||= nil

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
      cert = OpenSSL::X509::Certificate.new( File::read(@x509_cert) )
      prv_key = OpenSSL::PKey::RSA.new( File::read(@x509_key), @x509_passphrase)

      begin
        # We add the encapsulated mail as attachement
#        m.parts << mail

        # Sign the mail
        # NOTE: the one following line is the slowest part of this code, signing is sloooow
        p7sign = OpenSSL::PKCS7.sign(cert,prv_key,mail.encoded, [], OpenSSL::PKCS7::DETACHED)
        smime0 = OpenSSL::PKCS7::write_smime(p7sign)

        # Adding the signature part to the older mail
        # NOTE: we can not reparse the whole mail, TMail adds a \r\n which breaks the signature...
        newm = Mail.new(smime0)
       # for part in newm.parts do
       #   if part.content_type =~ /application\/x-pkcs7-signature/
       #     #part.body = part.body.encoded.gsub(/\r|\n/, "").gsub(/(.{64})/){$1 + "\r\n"}
       #     m.parts << part
       #   end
       # end

        # We need to overwrite the content-type of the mail so MUA notices this is a signed mail
#        m.content_type = 'multipart/signed; protocol="application/x-pkcs7-signature"; micalg=sha1; '
         newm.delivery_method(mail.delivery_method.class, mail.delivery_method.settings)
         newm.subject = mail.subject
         newm.to = mail.to
         newm.cc = mail.cc
         newm.from = mail.from
         newm.mime_version = mail.mime_version
         newm.date = mail.date
#         newm.body = "This is an S/MIME signed message\n"
        # NOTE: We can not use this as we need a B64 encoded signature, and no
        # methods provides it within the Ruby OpenSSL library... :(
        #
        # We add the signature
        # signature = TMail::Mail.new
        # signature.mime_version = '1.0'
        # signature['Content-Type'] = 'application/x-pkcs7-mime; smime-type=signed-data; name="smime.p7m"'
        # signature['Content-Transfer-Encoding'] = 'base64'
        # signature['Content-Disposition']  = 'attachment; filename="smime.p7m"'
        # signature.body = p7sign.to_s
        # m.parts << signature

        @_message = newm
        #@_message = m
      rescue Exception => detail
        logger.error("Error while SMIME signing the mail : #{detail}")# if logger
      end

      ## logger.debug("x509_sign_smime, resulted email\n-------------( test X509 )----------\n#{m.encoded}\n-------------( test X509 )----------")

    end

    # X509 SMIME crypting
    def x509_crypt_smime(mail)
      logger.debug("X509 SMIME crypting")
    end

    protected

    # Shall we sign the mail?
    def should_sign?
      if @x509_sign == true
        if not @x509_cert.nil? and not @x509_key.nil?
          return true
        else
          logger.info "X509 signing required, but no certificate and key files configured"
        end
      end
      return false
    end

    # Initiate from the default class attributes
    def x509_initvar
      @x509_sign ||= @@default_x509_sign
      @x509_crypt ||= @@default_x509_crypt
      @x509_cert ||= @@default_x509_cert
      @x509_key ||= @@default_x509_key
      @x509_sign_method ||= @@default_x509_sign_method
      @x509_crypt_method ||= @@default_x509_crypt_method
      @x509_passphrase ||= @@default_x509_passphrase
    end
  end
end
