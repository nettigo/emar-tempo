Gem::Specification.new do |s|
  s.name = %q{emar-tempo}
  s.version = "0.0.3"
  s.date = %q{2019-06-28}
  s.authors= %q{Witold Rugowski}
  s.homepage = "https://github.com/nettigo/emar-tempo"
  s.summary = %q{Support for Emar Tempo Pro fiscal printer (https://emar.pl/urzadzenia-fiskalne/drukarki-fiskalne/tempo-pro-57mm-1-wyswietlacz/)}
  s.files             = `git ls-files`.split($\)
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'bunny', '~> 2.14'
  s.add_runtime_dependency 'serialport', '~> 1.3'
  s.add_runtime_dependency 'test-unit', '~> 3.2'
  s.add_runtime_dependency 'irb', '~> 1.0'
end