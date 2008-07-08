# depends on: class.rb enumerable.rb hash.rb

class Struct

  include Enumerable

  class << self
    alias subclass_new new
  end

  ##
  # call-seq:
  #   Struct.new( [aString] [, aSym]+> )    => StructClass
  #   StructClass.new(arg, ...)             => obj
  #   StructClass[arg, ...]                 => obj
  #
  # Creates a new class, named by <em>aString</em>, containing accessor
  # methods for the given symbols. If the name <em>aString</em> is omitted,
  # an anonymous structure class will be created. Otherwise, the name of
  # this struct will appear as a constant in class <tt>Struct</tt>, so it
  # must be unique for all <tt>Struct</tt>s in the system and should start
  # with a capital letter. Assigning a structure class to a constant
  # effectively gives the class the name of the constant.
  #
  # <tt>Struct::new</tt> returns a new <tt>Class</tt> object, which can then
  # be used to create specific instances of the new structure. The number of
  # actual parameters must be less than or equal to the number of attributes
  # defined for this class; unset parameters default to \nil{}. Passing too
  # many parameters will raise an \E{ArgumentError}.
  #
  # The remaining methods listed in this section (class and instance) are
  # defined for this generated class.
  #
  #    # Create a structure with a name in Struct
  #    Struct.new("Customer", :name, :address)    #=> Struct::Customer
  #    Struct::Customer.new("Dave", "123 Main")   #=> #<Struct::Customer
  # name="Dave", address="123 Main">
  #    # Create a structure named by its constant
  #    Customer = Struct.new(:name, :address)     #=> Customer
  #    Customer.new("Dave", "123 Main")           #=> #<Customer
  # name="Dave", address="123 Main">

  def self.new(klass_name, *attrs, &block)
    unless klass_name.nil? then
      begin
        klass_name = StringValue klass_name
      rescue TypeError
        attrs.unshift klass_name
        klass_name = nil
      end
    end

    begin
      attrs = attrs.map { |attr| attr.to_sym }
    rescue NoMethodError => e
      raise TypeError, e.message
    end

    raise ArgumentError if attrs.any? { |attr| attr.nil? }

    klass = Class.new self do

      attr_accessor(*attrs)

      def self.new(*args)
        return subclass_new(*args)
      end

      def self.[](*args)
        return new(*args)
      end

    end

    Struct.const_set klass_name, klass if klass_name

    klass.const_set :STRUCT_ATTRS, attrs

    klass.module_eval(&block) if block

    return klass
  end

  def self.allocate # :nodoc:
    super
  end

  def _attrs # :nodoc:
    return self.class.const_get(:STRUCT_ATTRS)
  end

  def instance_variables
    # Hide the ivars used to store the struct fields
    super() - _attrs.map { |a| "@#{a}" }
  end

  def initialize(*args)
    raise ArgumentError unless args.length <= _attrs.length
    _attrs.each_with_index do |attr, i|
      instance_variable_set "@#{attr}", args[i]
    end
  end

  private :initialize

  ##
  # call-seq:
  #   struct == other_struct     => true or false
  #
  # Equality---Returns <tt>true</tt> if <em>other_struct</em> is equal to
  # this one: they must be of the same class as generated by
  # <tt>Struct::new</tt>, and the values of all instance variables must be
  # equal (according to <tt>Object#==</tt>).
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe   = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joejr = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    jane  = Customer.new("Jane Doe", "456 Elm, Anytown NC", 12345)
  #    joe == joejr   #=> true
  #    joe == jane    #=> false

  def ==(other)
    return false if (self.class != other.class)
    return false if (self.values.size != other.values.size)
    
    self.values.size.times { |i|
      next if (RecursionGuard.inspecting?(self.values.at(i)))
      next if (RecursionGuard.inspecting?(other.values.at(i)))
      RecursionGuard.inspect(self.values.at(i)) do
        RecursionGuard.inspect(other.values.at(i)) do
          return false if (self.values.at(i) != other.values.at(i))
        end
      end
    }
    return true
  end

  ##
  # call-seq:
  #   struct[symbol]    => anObject
  #   struct[fixnum]    => anObject 
  #
  # Attribute Reference---Returns the value of the instance variable named
  # by <em>symbol</em>, or indexed (0..length-1) by <em>fixnum</em>. Will
  # raise <tt>NameError</tt> if the named variable does not exist, or
  # <tt>IndexError</tt> if the index is out of range.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe["name"]   #=> "Joe Smith"
  #    joe[:name]    #=> "Joe Smith"
  #    joe[0]        #=> "Joe Smith"

  def [](var)
    case var
    when Numeric then
      var = var.to_i
      a_len = _attrs.length
      if var > a_len - 1 then
        raise IndexError, "offset #{var} too large for struct(size:#{a_len})"
      end
      if var < -a_len then
        raise IndexError, "offset #{var + a_len} too small for struct(size:#{a_len})"
      end
      var = _attrs[var]
    when Symbol, String then
      42 # HACK
      # ok
    else
      raise TypeError
    end

    unless _attrs.include? var.to_sym then
      raise NameError, "no member '#{var}' in struct"
    end

    return instance_variable_get("@#{var}")
  end

  ##
  # call-seq:
  #   struct[symbol] = obj    => obj
  #   struct[fixnum] = obj    => obj
  #
  # Attribute Assignment---Assigns to the instance variable named by
  # <em>symbol</em> or <em>fixnum</em> the value <em>obj</em> and returns
  # it. Will raise a <tt>NameError</tt> if the named variable does not
  # exist, or an <tt>IndexError</tt> if the index is out of range.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe["name"] = "Luke"
  #    joe[:zip]   = "90210"
  #    joe.name   #=> "Luke"
  #    joe.zip    #=> "90210"

  def []=(var, obj)
    case var
    when Numeric then
      var = var.to_i
      a_len = _attrs.length
      if var > a_len - 1 then
        raise IndexError, "offset #{var} too large for struct(size:#{a_len})"
      end
      if var < -a_len then
        raise IndexError, "offset #{var + a_len} too small for struct(size:#{a_len})"
      end
      var = _attrs[var]
    when Symbol, String then
      42 # HACK
      # ok
    else
      raise TypeError
    end

    unless _attrs.include? var.to_s.intern then
      raise NameError, "no member '#{var}' in struct"
    end

    return instance_variable_set("@#{var}", obj)
  end

  ##
  # call-seq:
  #   struct.each {|obj| block }  => struct
  #
  # Calls <em>block</em> once for each instance variable, passing the value
  # as a parameter.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.each {|x| puts(x) }
  #
  # <em>produces:</em>
  #
  #    Joe Smith
  #    123 Maple, Anytown NC
  #    12345

  def each(&block)
    return values.each(&block)
  end

  ##
  # call-seq:
  #   struct.each_pair {|sym, obj| block }     => struct
  #
  # Calls <em>block</em> once for each instance variable, passing the name
  # (as a symbol) and the value as parameters.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.each_pair {|name, value| puts("#{name} => #{value}") }
  #
  # <em>produces:</em>
  #
  #    name => Joe Smith
  #    address => 123 Maple, Anytown NC
  #    zip => 12345

  def each_pair
    raise LocalJumpError unless block_given? # HACK yield should do this
    _attrs.map { |var| yield var, instance_variable_get("@#{var}") }
  end

  ##
  # call-seq:
  #   (p1)
  #
  # code-seq:
  #
  #   struct.eql?(other)   => true or false
  #
  # Two structures are equal if they are the same object, or if all their
  # fields are equal (using <tt>eql?</tt>).

  def eql?(other)
    return true if self == other
    return false if self.class != other.class
    to_a.eql? other
  end

  ##
  # call-seq:
  #   struct.hash   => fixnum
  #
  # Return a hash value based on this struct's contents.

  def hash
    to_a.hash
  end

  ##
  # call-seq:
  #   struct.length    => fixnum
  #   struct.size      => fixnum
  #
  # Returns the number of instance variables.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.length   #=> 3

  def length
    return _attrs.length
  end

  alias size length

  ##
  # call-seq:
  #   struct.members    => array
  #
  # Returns an array of strings representing the names of the instance
  # variables.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.members   #=> ["name", "address", "zip"]

  def self.members
    return const_get(:STRUCT_ATTRS).map { |member| member.to_s }
  end

  def members
    return self.class.members
  end

  ##
  # call-seq:
  #   struct.select(fixnum, ... )   => array
  #   struct.select {|i| block }    => array
  #
  # The first form returns an array containing the elements in
  # <em>struct</em> corresponding to the given indices. The second form
  # invokes the block passing in successive elements from <em>struct</em>,
  # returning an array containing those elements for which the block returns
  # a true value (equivalent to <tt>Enumerable#select</tt>).
  #
  #    Lots = Struct.new(:a, :b, :c, :d, :e, :f)
  #    l = Lots.new(11, 22, 33, 44, 55, 66)
  #    l.select(1, 3, 5)               #=> [22, 44, 66]
  #    l.select(0, 2, 4)               #=> [11, 33, 55]
  #    l.select(-1, -3, -5)            #=> [66, 44, 22]
  #    l.select {|v| (v % 2).zero? }   #=> [22, 44, 66]

  def select(&block)
    to_a.select(&block)
  end

  ##
  # call-seq:
  #   struct.to_a     => array
  #   struct.values   => array
  #
  # Returns the values for this instance as an array.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.to_a[1]   #=> "123 Maple, Anytown NC"

  def to_a
    return _attrs.map { |var| instance_variable_get "@#{var}" }
  end

  ##
  # call-seq:
  #   struct.to_s      => string
  #   struct.inspect   => string
  #
  # Describe the contents of this struct in a string.

  def to_s
    return "[...]" if RecursionGuard.inspecting?(self)
  
    RecursionGuard.inspect(self) do
      "#<struct #{self.class.name} #{_attrs.zip(self.to_a).map{|o| o[1] = o[1].inspect; o.join('=')}.join(', ') }>"
    end
  end

  alias inspect to_s

  ##
  # call-seq:
  #   struct.to_a     => array
  #   struct.values   => array
  #
  # Returns the values for this instance as an array.
  #
  #    Customer = Struct.new(:name, :address, :zip)
  #    joe = Customer.new("Joe Smith", "123 Maple, Anytown NC", 12345)
  #    joe.to_a[1]   #=> "123 Maple, Anytown NC"

  alias values to_a

  ##
  # call-seq:
  #   struct.values_at(selector,... )  => an_array
  #
  # Returns an array containing the elements in <em>self</em> corresponding
  # to the given selector(s). The selectors may be either integer indices or
  # ranges. See also </code>.select<code>.
  #
  #    a = %w{ a b c d e f }
  #    a.values_at(1, 3, 5)
  #    a.values_at(1, 3, 5, 7)
  #    a.values_at(-1, -3, -5, -7)
  #    a.values_at(1..3, 2...5)

  def values_at(*args)
    to_a.values_at(*args)
  end
end

