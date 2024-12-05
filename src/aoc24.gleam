import gleam/int
import gleam/io
import gleam/result

import day2_part2
import utils

pub fn main() {
  let reports =
    utils.read_file("./inputs/day2_part1.txt")
    |> result.map(utils.create_reports)
    |> result.flatten

  let num = case reports {
    Ok(r) -> day2_part2.num_dampened_reports(r)
    _ -> {
      -1
    }
  }

  io.println(int.to_string(num))
}
