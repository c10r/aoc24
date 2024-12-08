import gleam/int
import gleam/io

import day8_part2
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day8_part5.txt")

  case content {
    Ok(content) -> {
      let total = day8_part2.antinode_count(content)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
