import gleam/int
import gleam/io

import day7_part1
import utils

pub fn main() {
  let content = utils.read_file("./inputs/day7_part1.txt")
  case content {
    Ok(content) -> {
      let total = day7_part1.total_calibration(content)
      io.println(int.to_string(total))
    }
    _ -> io.println("Corrupt file")
  }
}
