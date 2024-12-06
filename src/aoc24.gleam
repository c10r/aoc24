import gleam/int
import gleam/io
import gleam/result

import day4_part1
import utils

pub fn main() {
  utils.read_file("./inputs/day4_part1.txt")
  |> result.map(fn(content) { day4_part1.crossword_count(content, "XMAS") })
  |> result.map(int.to_string)
  |> result.map(io.println)
}
