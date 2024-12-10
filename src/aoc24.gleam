import gleam/int
import gleam/io

import day10_part1
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day10_part6.txt")

  case content {
    Ok(content) -> {
      let total = day10_part1.trailhead_rating(content)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
