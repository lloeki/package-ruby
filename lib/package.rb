require 'binding_of_caller'

#
class Package < Module
  #
  module KernelMethods
    NS_SEP = '/'

    module_function

    # Return the package as a value
    def import(caller_binding, namespace, as: nil, to: :method)
      to ||= :value

      send("import_to_#{to}", caller_binding, namespace, as: as)
    end

    # Return the package as a value
    def import_to_value(_binding, namespace, as: nil)
      Package.new(namespace)
    end

    # Assign the package to a local variable in the caller's binding
    # Return the package as a value
    # /!\ Experimental
    def import_to_local(caller_binding, namespace, as: nil)
      sym = (as || ns_last(namespace)).to_sym
      setter = caller_binding.eval(<<-RUBY)
        #{sym} = nil
        -> (v) { #{sym} = v }
      RUBY

      setter.call(Package.new(namespace))
    end

    # Define a method in the caller's context that hands out the package
    # Return the package as a value
    def import_to_method(caller_binding, namespace, as: nil)
      sym = (as || ns_last(namespace)).to_sym
      clr = caller_binding.eval('self')
      setter = clr.instance_eval(<<-RUBY)
        -> (v) { define_singleton_method(:#{sym}) { v }; v }
      RUBY

      setter.call(Package.new(namespace))
    end

    # Set a const to the package in the caller's context
    # Return the package as a value
    def import_to_const(caller_binding, namespace, as: nil)
      sym = (as || ns_classify(ns_last(namespace)).to_sym)
      clr = caller_binding.eval('self')
      target = clr.respond_to?(:const_set) ? clr : clr.class
      setter = target.instance_eval(<<-RUBY)
        -> (v) { const_set(:#{sym}, v) }
      RUBY

      setter.call(Package.new(namespace))
    end

    def ns_from_filename(ns)
      ns.gsub('/', NS_SEP).gsub(/\.rb$/, '')
    end

    def ns_to_filename(ns)
      ns.gsub(NS_SEP, '/') + '.rb'
    end

    def ns_last(ns)
      ns.split(NS_SEP).last
    end

    def ns_classify(namespace)
      namespace.split(NS_SEP).map! do |v|
        v.split('_').map!(&:capitalize).join('')
      end.join('::')
    end
  end

  class << self
    def new(file)
      file = KernelMethods.ns_to_filename(file)
      self[file] ||= super(file)
    end

    def [](key)
      loaded[key]
    end

    def []=(key, value)
      loaded[key] = value
    end

    def loaded
      @store ||= {}
    end

    def delete(ns)
      @store.delete(ns_to_filename(ns))
    end

    def reload!
      @store = {}
    end

    def path
      $LOAD_PATH
    end
  end

  def initialize(file)
    @source_file = file
    @name = KernelMethods.ns_from_filename(file)
    load_in_module(file)
  end

  attr_reader :name
  alias_method :to_s, :name

  def load(file, wrap = false)
    wrap ? super : load_in_module(File.join(dir, file))
  rescue Errno::ENOENT
    super
  end

  def inspect
    format("#<#{self.class.name}(#{name}):0x%014x>", object_id)
  end

  private

  def load_in_module(file)
    module_eval(IO.read(file),
                File.expand_path(file))
  rescue Errno::ENOENT
    raise
  end

  def method_added(name)
    module_function(name)
  end
end

#
module Kernel
  def import(*args)
    caller_binding = args.last.is_a?(Binding) ? args.pop : binding.of_caller(1)
    args.unshift(caller_binding)
    Package::KernelMethods.import(*args)
  end
end
