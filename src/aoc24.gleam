import gleam/int
import gleam/io

import day14
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day14_part2.txt")

  case content {
    Ok(content) -> {
      let total = day14.safety_factor(content, 103, 101)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
