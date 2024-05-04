package xod

import "core:os"
import "core:unicode/utf8"
import "core:fmt"
import color "./external/odin-color"

to_printable_ascii :: proc(byte: u8) -> rune {
  if byte >= 32 && byte < 127 {
    return rune(byte)
  } else {
    return rune('.')
  }
}

hexchar :: proc(nibble: u8) -> (char: u8, ok: bool) {
  switch nibble {
    case 0..=9:
      return nibble+48, true
    case 10..<16:
      return nibble+87, true 
  }
  return 0, false
}

hex_to_runes :: proc(byte: u8) -> (rune, rune) {
  upper, u_ok := hexchar(byte / 16)
  lower, l_ok := hexchar(byte % 16)

  return rune(upper), rune(lower)
}

clear_array :: proc(arr: []rune) {
  for &elem in arr {
    elem = 0
  }
}

get_color :: proc(byte: u8) -> []rune {
  using color
  switch byte {
    case 0x00:
      return utf8.string_to_runes(BRIGHT_WHITE)
    case 0x09, 0x0a, 0x0d:
      return utf8.string_to_runes(BRIGHT_YELLOW)
    case 0x20..<0x7f:
      return utf8.string_to_runes(BRIGHT_GREEN)
    case:
      return utf8.string_to_runes(BRIGHT_RED)
  }
}

to_string :: proc{utf8.runes_to_string}


main :: proc() {
  if len(os.args) < 2 {
    fmt.eprintln("Usage:\n", os.args[0], "<filenames>")
    os.exit(64)
  }

  buf := new([dynamic]u8)
  defer delete(buf^)

  for arg in os.args[1:] {
    switch {
      case !os.is_file(arg):
        fmt.eprintln(arg, "is not a file!")
        os.exit(65)
      case !os.exists(arg):
        fmt.eprintln(arg, "doesn't exist!")
        os.exit(66)
    }

    data, ok := os.read_entire_file(arg)
    if !ok {
      fmt.eprintln("Error reading", arg)
      os.exit(66)
    }
    defer delete(data)

    byte_linelen : int
    bytes:     [dynamic]rune
    printable: [16]rune
    defer delete(bytes)

    for byte, i in data {
      if i % 16 == 0 && i > 0 {
        byte_linelen = 0
        fmt.printf("%08x: %s%-123s%s%s\n", i-16, color.BOLD, to_string(bytes[:]), color.RESET, to_string(printable[:]))
        clear(&bytes)
        clear_array(printable[:])
      }

      if i % 2 == 0 && i % 16 != 0 {
        append(&bytes, ' ')
      }

      for c in get_color(byte) {
        append(&bytes, c)
      }
      append(&bytes, hex_to_runes(byte))
      byte_linelen += 3

      printable[i % 16] = to_printable_ascii(byte)
    }
    fmt.printf("%08x: %s%s", len(data)-len(data)%16, color.BOLD, to_string(bytes[:]))
    // dirty hack for the time being, format strings won't behave
    for i in 0..<52-byte_linelen {
      fmt.printf(" ");
    }
    fmt.printf("%s%s\n", color.RESET, to_string(printable[:]))
  }
}
