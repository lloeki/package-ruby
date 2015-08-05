# rubocop:disable all

$LOAD_PATH.push File.expand_path(File.join(File.dirname(__FILE__), 'lib'))

require 'pry'
require 'binding_of_caller'
require 'package'


if __FILE__ == $PROGRAM_NAME
  Dir.chdir('test')

  import('foo')
  p foo
  puts foo.name
  puts foo.hello
  puts foo::HELLO

  import('foo', as: :fee)
  p fee
  puts fee.name
  puts fee.hello
  puts fee::HELLO

  import('foo', to: :const)
  p Foo
  puts Foo.name
  puts Foo.hello
  puts Foo::HELLO

  import('bar')
  p bar
  p bar.name
  p bar.hello
  p bar.foo
  p bar.foo.name

  import('foo/baz', as: 'baz2')
  p baz2.name

  import('foo/baz')
  p baz.name

  p Package.loaded
end

class ABC; end

p ABC.new.foo
