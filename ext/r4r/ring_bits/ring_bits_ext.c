#include <ruby.h>
#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>

#define ADDRESS_BITS_PER_WORD 6

struct ring_bits_ext {
  size_t size; //the size of the ring bit set
  uint64_t * words;
};

/**
 * Free resources allocated for ring_bits_ext.
 */
static void
ring_bits_ext_free(void *p) {
  struct ring_bits_ext *ptr = p;
  if (ptr->size > 0) {
    free(ptr->words);
  }
}

/**
 * Given a bit index, return word index containing it.
 */
size_t
ring_bits_ext_word_index(int bit_index) {
  return bit_index >> ADDRESS_BITS_PER_WORD;
}

/**
 * Allocates resources for a ring_bits_ext.
 */
static VALUE
ring_bits_ext_alloc(VALUE klass) {
  VALUE obj;
  struct ring_bits_ext *ptr;

  obj = Data_Make_Struct(klass, struct ring_bits_ext, NULL, ring_bits_ext_free, ptr);
  ptr->size = 0;
  ptr->words = NULL;

  return obj;
}
/**
 * Inits a new ring_bits_ext object.
 *
 * * *Args*:
 *   - +capacity+:: a ring bits buffer size.
 * * *Raises*:
 *   - ArgumentError if capacity is negative
 */
static VALUE
ring_bits_ext_init(VALUE self, VALUE capacity) {
  struct ring_bits_ext *ptr;
  int ring_bits_ext_size = NUM2INT(capacity);

  if (0 >= ring_bits_ext_size) {
    rb_raise(rb_eArgError, "ring bit's size must be positive, got %i", ring_bits_ext_size);
    return Qnil;
  }

  size_t count_of_words_required = ring_bits_ext_word_index(ring_bits_ext_size - 1) + 1;

  Data_Get_Struct(self, struct ring_bits_ext, ptr);
  ptr->size = count_of_words_required << ADDRESS_BITS_PER_WORD;
  ptr->words = calloc(count_of_words_required, sizeof(uint64_t));

  return self;
}

/**
 * Returns an actual ring bits capacity.
 */
static VALUE
ring_bits_ext_get_size(VALUE self) {
  struct ring_bits_ext *ptr;
  Data_Get_Struct(self, struct ring_bits_ext, ptr);
  return SIZET2NUM(ptr->size);
}

bool
_ring_bits_ext_set(struct ring_bits_ext *ptr, int bit_index, bool value) {
  assert(bit_index >= 0);

  size_t word_index = ring_bits_ext_word_index(bit_index);

  uint64_t bit_mask = ((uint64_t) 1) << bit_index;
  bool previous = (ptr->words[word_index] & bit_mask) != 0;

  //fprintf(stderr, "set: word_index: %lu bit_index: %i bit_mask: %llx \n", word_index, bit_index, bit_mask);

  if (value) {
    ptr->words[word_index] |= bit_mask;
  } else {
    ptr->words[word_index] &= ~bit_mask;
  }

  return previous;
}

/**
 * Sets the bit at the specified index to value.
 *
 * * *Args*:
 *   - +bit_index_value+:: a bit index
 * * *Returns*:
 *   - previous state of bit_index that can be true or false
 * * *Raises*:
 *   - ArgumentError if the specified index is negative
 */
static VALUE
ring_bits_ext_set(VALUE self, VALUE bit_index_value, VALUE value) {
  struct ring_bits_ext *ptr;
  Data_Get_Struct(self, struct ring_bits_ext, ptr);

  int bit_index = NUM2INT(bit_index_value);
  if (0 > bit_index) {
    rb_raise(rb_eArgError, "ring bit's index must be positive, got %i", bit_index);
  }

  bool previous = _ring_bits_ext_set(ptr, bit_index, value == Qtrue);
  return previous ? Qtrue : Qfalse;
}

bool
_ring_bits_ext_get(struct ring_bits_ext *ptr, int bit_index) {
  assert(0 <= bit_index);

  size_t word_index = ring_bits_ext_word_index(bit_index);
  uint64_t bit_mask = ((uint64_t) 1) << bit_index;

  //fprintf(stderr, "get: word_index: %lu bit_index: %i bit_mask: %llx\n", word_index, bit_index, bit_mask);

  return (ptr->words[word_index] & bit_mask) != 0;
}

/**
 * Gets the bit at the specified index.
 *
 * * *Args*:
 *   - +bit_index+:: a bit index
 * * *Returns*:
 *   - state of bit_index that can be true or false
 * * *Raises*:
 *   - ArgumentError if the specified index is negative
 */
static VALUE
ring_bits_ext_get(VALUE self, VALUE bit_index_value) {
  struct ring_bits_ext *ptr;
  Data_Get_Struct(self, struct ring_bits_ext, ptr);

  int bit_index = NUM2INT(bit_index_value);
  if (0 > bit_index) {
    rb_raise(rb_eArgError, "ring bit's index must be positive, got %i", bit_index);
  }

  bool value = _ring_bits_ext_get(ptr, bit_index);
  return value ? Qtrue : Qfalse;
}

/**
 * Module entry point.
 */
void
Init_ring_bits_ext() {
  VALUE mR4r;
  VALUE cRingBitSet;

  mR4r = rb_define_module("R4r");
  cRingBitSet = rb_define_class_under(mR4r, "RingBitsExt", rb_cObject);

  rb_define_alloc_func(cRingBitSet, ring_bits_ext_alloc);
  rb_define_method(cRingBitSet, "initialize", ring_bits_ext_init, 1);
  rb_define_method(cRingBitSet, "size", ring_bits_ext_get_size, 0);
  rb_define_method(cRingBitSet, "set", ring_bits_ext_set, 2);
  rb_define_method(cRingBitSet, "get", ring_bits_ext_get, 1);
}
