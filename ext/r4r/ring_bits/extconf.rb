require "mkmf"

$CFLAGS = "-O2 -Wall -std=c99"

extension_name = 'ring_bits_ext'
dir_config(extension_name)
create_makefile "#{extension_name}"
