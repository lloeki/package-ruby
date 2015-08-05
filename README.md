# Pak - A namespaced package system for Ruby

## Why, oh why?

If you are:

- sick of side effects when requiring?
- think writing namespaces when you're already nested deep in directories is
  not quite DRY?
- want easier reloading/dependency tracking/source mapping?

You've come to the right place.

## A quick note about require, monkeys, and use cases

I have no issue *per se* with monkey-patching, require being side-effectful WRT
namespacing by design, and classes (modules, really) being open. The trouble
is, most of the time it's not what we need, and more often than not it gets in
the way in terrible ways. Hence, this, taking inspiration from Python and Go.

## An example, for good measure

Take a module named `foo.rb`:

````ruby
HELLO = 'FOO'

def hello
  'i am foo'
end
```

Importing `foo` will make it accessible to `self`:

```ruby
import('foo', as: :method)
p foo              #=> #<Package foo>
p foo.name         #=> "foo"
p foo.hello        #=> "i am foo"
p foo::HELLO       #=> "FOO"
```

To avoid pollution (especially with `main` being a special case of `Object`),
import defines a `.foo` method on the caller's `class << self`, so that `foo`
may not become accessible from too much unexpected places.

```ruby
class ABC; end
p ABC.new.foo      # NoMethodError
```

You can import under another name to prevent conflict:

```ruby
import('foo', as: :fee)
p fee              #=> #<Package foo>
p fee.name         #=> "foo"
p fee.hello        #=> "i am foo"
p fee::HELLO       #=> "FOO"
```

Alternatively, you can import as a const:

```ruby
import('foo', to: :const)
p Foo              #=> #<Package foo>
p Foo.name         #=> "foo"
p Foo.hello        #=> "i am foo"
p Foo::HELLO       #=> "FOO"
```

And if that doesn't suit you, you can import as a local:

```ruby
qux = import('foo', to: nil)
p qux
puts qux.name
puts qux.hello
puts qux::HELLO
```

From a package `bar.rb`, you can import `foo`...:

```ruby
import 'foo'

HELLO = 'BAR'

def hello
  "i am bar and I can access #{foo.name}"
end
```

...all without polluting anyone:

```ruby
import('bar')
p bar
p bar.name
p bar.hello
p foo             # NameError
```

Note that `foo` as used by `bar` is visible to the world:

```ruby
p bar.foo
p bar.foo.name
```

Packages can be nested. Here's a surprising `foo/baz.rb` file:

```ruby
HELLO = 'BAZ'

def hello
  'i am baz'
end
```

You can guess how to use it:

```ruby
import('foo/baz')
p baz             # #<Package foo/baz>
p baz.name
p baz.hello
p foo             # NameError
```

Importing a package will load the package only once, as future import calls
will reuse the cached version. Loaded packages can be listed and manipulated,
allowing a reload for future instances.

```ruby
foo.object_id        #=> 70151878063900
p Package.loaded     #=> {"foo.rb"=>#<Package foo>, ...}
# old_foo = Package.delete("foo")
old_foo = Package.loaded.delete("foo.rb")
import 'foo'
foo.object_id        #=> 70151879713940
```

`foo` in `bar` will be reloaded once bar itself is reloaded. The logic is that
while you *may* want new code to be reloaded by old code sometimes, you'd
rather not have old code call new code in an incompatible manner. So, to
minimize surprise, global (i.e unscoped const) reload is declared a bad thing
and module scoped reload is favored.

```ruby
bar.foo.object_id == old_foo.object_id   #=> true
```

Dependency tracking becomes easy, and reloading a whole graph just as well:

```ruby
bar.dependencies   #=> 'foo'
bar = bar.reload!  # evicts dependencies recursively and reimports bar
```

## Wishlist: setting locals directly

I hoped to be able to have an implicit syntax similar to Python or Go allowing
for real local variable setting, but this seems unlikely given how local
variables are set up by the Ruby VM: although you can get the
`binding.of_caller`, modifying the binding doesn't *create* the variable as a
caller's local. As such, you can guess how being forced to do `foo = nil;
import 'foo'` is not really useful (and entirely arcane) when compared to `foo
= import 'foo'`.

See how [`bind_local_variable_set`][1] works on a binding, defining new vars
dynamically inside the binding but outside the local table, resulting in the
following behavior (excerpted form Ruby's own inline doc):

```ruby
def foo
  a = 1
  b = binding
  b.local_variable_set(:a, 2) # set existing local variable `a'
  b.local_variable_set(:b, 3) # create new local variable `b'
                              # `b' exists only in binding.
  b.local_variable_get(:a) #=> 2
  b.local_variable_get(:b) #=> 3
  p a #=> 2
  p b #=> NameError
end
```

A good way to look at the local table is to use RubyVM ISeq features:

    > puts RubyVM::InstructionSequence.disasm(-> { foo=42 })
    == disasm: <RubyVM::InstructionSequence:block in __pry__@(pry)>=========
    == catch table
    | catch type: redo   st: 0002 ed: 0009 sp: 0000 cont: 0002
    | catch type: next   st: 0002 ed: 0009 sp: 0000 cont: 0009
    |------------------------------------------------------------------------
    local table (size: 2, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, keyword: 0@3] s1)
    [ 2] foo
    0000 trace            256                                             (  13)
    0002 trace            1
    0004 putobject        42
    0006 dup
    0007 setlocal_OP__WC__0 2
    0009 trace            512
    0011 leave
    => nil

That's because, IIUC, the local variables table is basically fixed and cannot
be changed, so the binding works around that with dynavars, but it doesn't
bubble up to the function local table.

[1]: https://github.com/ruby/ruby/blob/6b6ba319ea4a5afe445bad918a214b7d5691fd7c/proc.c#L473
