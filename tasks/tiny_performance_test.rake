# Copyright (c) 2007 Fabien Penso <fabien.penso@conovae.com>
#
# A simple test to show how slow is the Ruby/SSL signature function
# 
# All rights reserved.

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require "openssl"

def sign_single_body_pipe

  body = <<"EOF"
Date: Fri, 01 Jan 2008 11:57:45 +0100
From: demo@foobar.com
To: destination@foobar.com
Subject: Empty subject for signed
Mime-Version: 1.0

This is the body of the mail
EOF

    require 'tempfile'

    tf = Tempfile.new('actionmailer_x509')
    tf.write body
    tf.flush

		tf2 = Tempfile.new('actionmailer_x509')
		tf2.flush

		comm = "openssl smime -sign -passin pass:demo -in #{tf.path} -text -out #{tf2.path} -signer #{File.dirname(__FILE__)}/../lib/certs/server.crt -inkey #{File.dirname(__FILE__)}/../lib/certs/server.key"

		system(comm)

end

def sign_single_body

  body = <<"EOF"
Date: Fri, 01 Jan 2008 11:57:45 +0100
From: demo@foobar.com
To: destination@foobar.com
Subject: Empty subject for signed
Mime-Version: 1.0

This is the body of the mail
EOF

  cert = OpenSSL::X509::Certificate.new( File::read("#{File.dirname(__FILE__)}/../lib/certs/server.crt") )
  prv_key = OpenSSL::PKey::RSA.new( File::read("#{File.dirname(__FILE__)}/../lib/certs/server.key"), "demo")

  p7sign = OpenSSL::PKCS7.sign(cert,prv_key,body, [], OpenSSL::PKCS7::DETACHED)

  #smime0 = OpenSSL::PKCS7::write_smime(p7sign)

end

namespace :actionmailer_x509 do

  #desc "Tiny Performance test."
  task(:tiny_performance_test => :environment) do
    require 'benchmark'

    n = 100
    Benchmark.bm do |x|
      x.report("#{n} loops with pipe") {
        for i in 1..n do
          sign_single_body_pipe
        end
      }
      x.report("#{n} loops Ruby/SSL") {
        for i in 1..n do
          sign_single_body
        end
      }
    end
  end

end
