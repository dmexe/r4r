#include <ruby.h>
#include <sys/time.h>

/**
 * Returns current system time in milliseconds.
 */
static VALUE
system_clock_call(VALUE self) {
  struct timeval tv;
  long long millis;

  gettimeofday(&tv, NULL);

  millis = ((long long)tv.tv_sec) * 1000;
  millis = millis + (tv.tv_usec / 1000);

  return LONG2NUM(millis);
}

/**
 * Module entry point.
 */
void
Init_system_clock_ext() {
  VALUE mR4r;
  VALUE cSystemClock;

  mR4r = rb_define_module("R4r");
  cSystemClock = rb_define_class_under(mR4r, "SystemClockExt", rb_cObject);
  rb_define_method(cSystemClock, "call", system_clock_call, 0);
}
