require 'pp'
#require 'pry'
require 'binding_of_caller'

def cards
  ace = 'of hearts'
  queen = 'of diamonds'
  binding
end

c = cards

pp c.eval('ace')
pp c.eval('ace = "of spades"')
pp c.eval('ace')
pp c.eval('foo = 42')
pp c.eval('foo')

def set_baz(b)
  b.eval('baz = 44')
  pp b.eval('baz')
  pp binding.callers
end

def meh
  foo = 42
  bar = 43
  #baz = nil

  set_baz binding
  binding
end

m = meh

pp m.eval('foo')
pp m.eval('bar')
pp m.eval('baz')
