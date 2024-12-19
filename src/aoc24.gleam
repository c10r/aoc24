import gleam/int
import gleam/io

import day15
import utils

pub fn main() {
  let maze = utils.read_file("./inputs/day15_part3_1.txt")
  let moves = utils.read_file("./inputs/day15_part3_2.txt")

  case maze, moves {
    Ok(m1), Ok(m2) -> {
      let result = day15.gps_coordinates(m1, m2)
      io.println(result |> int.to_string)
    }
    _, _ -> io.println("Corrupt file")
  }
}
