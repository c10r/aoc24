import gleam/int
import gleam/io

import day9
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day9_part1.txt")

  case content {
    Ok(content) -> {
      let total = day9.checksum(content)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
