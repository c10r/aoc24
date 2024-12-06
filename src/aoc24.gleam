import gleam/int
import gleam/io
import gleam/result

import day3_part1
import utils

pub fn main() {
  utils.read_file("./inputs/day3_part1.txt")
  |> result.map(day3_part1.multiply)
  |> result.map(int.to_string)
  |> result.map(io.println)
}
