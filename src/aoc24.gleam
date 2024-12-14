import gleam/int
import gleam/io

import day13
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day13_part2.txt")

  case content {
    Ok(content) -> {
      let total = day13.fewest_tokens(content, True)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
