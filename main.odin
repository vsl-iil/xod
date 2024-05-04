package xod

import "core:os"
import "core:unicode/utf8"
import "core:fmt"

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

    bytes:     [dynamic]rune
    printable: [16]rune
    defer delete(bytes)

    for byte, i in data {
      if i % 16 == 0 && i > 0 {
        fmt.printf("%08x: %-41s%s\n", i-16, to_string(bytes[:]), to_string(printable[:]))
        clear(&bytes)
        clear_array(printable[:])
      }

      if i % 2 == 0 && i % 16 != 0 {
        append(&bytes, ' ')
      }
      append(&bytes, hex_to_runes(byte))

      printable[i % 16] = to_printable_ascii(byte)
    }
    fmt.printf("%08x: %-41s%s\n", len(data)-len(data)%16, to_string(bytes[:]), to_string(printable[:]))
  }
}
