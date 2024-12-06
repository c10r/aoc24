import gleam/int
import gleam/io

import day5_part1
import utils

pub fn main() {
  let orders = utils.read_file("./inputs/day5_part2_1.txt")
  let updates = utils.read_file("./inputs/day5_part2_2.txt")

  let res = case updates, orders {
    Ok(u), Ok(o) -> day5_part1.get_incorrect_update_middles(u, o)
    _, _ -> -1
  }

  io.println(int.to_string(res))
}
