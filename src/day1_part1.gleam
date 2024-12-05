import gleam/int
import gleam/list
import gleam/pair
import gleam/result

import utils

pub fn total_distance(filename: String) -> Result(Int, Nil) {
  utils.read_file(filename)
  |> result.map(fn(content) {
    utils.create_list(content)
    |> result.map(fn(x) { helper(pair.first(x), pair.second(x)) })
    |> result.flatten
  })
  |> result.flatten
}

fn helper(list1: List(Int), list2: List(Int)) -> Result(Int, Nil) {
  let #(list1, list2) = #(
    list.sort(list1, by: int.compare),
    list.sort(list2, by: int.compare),
  )
  let #(length1, length2) = #(list.length(list1), list.length(list2))
  let #(smaller, larger) = case length1 - length2 {
    n if n < 0 -> #(list1, list2)
    n if n > 0 -> #(list2, list1)
    _ -> #(list1, list2)
  }

  let result =
    list.map2(smaller, larger, fn(x, y) { int.absolute_value(x - y) })
    |> list.reduce(fn(x, y) { x + y })

  case result {
    Ok(num) -> Ok(num)
    _ -> Error(Nil)
  }
}
