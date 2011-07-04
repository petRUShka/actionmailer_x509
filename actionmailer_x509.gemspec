Gem::Specification.new do |s|
  s.name = "actionmailer_x509"
  s.version = "0.3.0"
  s.authors = ["Fabien Penso", "CONOVAE", "petRUShka"]
  s.email = "petrushkin@yandex.ru"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = "http://github.com/petRUShka/actionmailer_x509"
  s.require_path = "lib"
  s.rubygems_version = "1.3.5"
  s.summary = "This Rails plugin allows you to send X509 signed mails."
end

