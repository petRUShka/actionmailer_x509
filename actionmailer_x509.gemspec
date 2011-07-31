Gem::Specification.new do |s|
  s.name = "actionmailer_x509"
  s.version = "0.4.0"
  s.authors = ["petRUShka", "Fabien Penso", "CONOVAE"]
  s.email = "petrushkin@yandex.ru"
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.homepage = "http://github.com/petRUShka/actionmailer_x509"
  s.require_path = "lib"
  s.rubygems_version = "1.3.5"
  s.summary = "This Rails 3 plugin allows you to send X509 signed and\\or crypted mails."
end

