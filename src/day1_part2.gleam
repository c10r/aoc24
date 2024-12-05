import gleam/dict
import gleam/list
import gleam/pair
import gleam/result

import utils

pub fn similarity(filename: String) -> Result(Int, Nil) {
  utils.read_file(filename)
  |> result.map(fn(content) {
    let lists = utils.create_list(content)

    lists
    |> result.map(fn(x) { helper(pair.first(x), pair.second(x)) })
    |> result.flatten
  })
  |> result.flatten
}

fn helper(list1: List(Int), list2: List(Int)) -> Result(Int, Nil) {
  let freq = item_frequency(list2)

  list.map(list1, fn(num) {
    dict.get(freq, num)
    |> result.map(fn(x) { x * num })
    |> result.unwrap(0)
  })
  |> list.reduce(fn(x, y) { x + y })
}

fn item_frequency(list: List(Int)) -> dict.Dict(Int, Int) {
  list
  |> list.group(fn(num) { num })
  |> dict.map_values(fn(_, value) { list.length(value) })
}
