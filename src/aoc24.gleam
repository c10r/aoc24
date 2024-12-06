import gleam/int
import gleam/io

import day6_part1
import utils

pub fn main() {
  let maze = utils.read_file("./inputs/day6_part2.txt")
  case maze {
    Ok(content) -> {
      let squares = day6_part1.get_unique_squares(content)
      io.println(int.to_string(squares))
    }
    _ -> io.println("Corrupt file")
  }
}
