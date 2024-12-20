import gleam/int
import gleam/io

import day16
import utils

pub fn main() {
  let maze = utils.read_file("./inputs/day16_part2.txt")

  case maze {
    Ok(content) -> {
      let result = day16.lowest_score(content)
      io.println(result |> int.to_string)
    }
    _ -> io.println("Corrupt file")
  }
}
