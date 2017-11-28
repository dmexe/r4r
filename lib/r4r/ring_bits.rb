module R4r ; class RingBits
  attr_reader :index, :length, :cardinality

  # Creates a ring bit set whose size is large enough to explicitly
  # represent bits with indices in the range 0 through
  # size-1. All bits are initially set to false.
  #
  # @param [Fixnum] size the size of ring bits buffer
  # @raise [ArgumentError] if the specified size is negitive
  def initialize(size:, bit_set_class: nil)
    @size = size
    @bit_set = (bit_set_class || RingBitsExt).new(size.to_i)
    @is_full = false
    @index = -1
    @length = 0
    @cardinality = 0
  end

  # Current ring bits buffer size.
  def size
    @size
  end

  # An actual ring bits buffer capacity.
  def bit_set_size
    @bit_set.size
  end

  # Sets the bit at the next index to the specified value.
  #
  # @param [Boolean] value is a boolean value to set
  # @return [Fixnum] the number of bits set to true
  def set_next(value)
    increase_length

    new_index = (@index + 1) % @size
    previous = @bit_set.set(new_index, value == true) ? 1 : 0
    current = value == true ? 1 : 0


    @index = new_index
    @cardinality = @cardinality - previous + current
  end

  private

  def increase_length
    return if @is_full

    next_length = @length + 1
    if (next_length < @size)
      @length = next_length
    else
      @length = size
      @is_full = true
    end
  end

end ; end
