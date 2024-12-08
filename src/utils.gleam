import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/string_tree

import simplifile

pub fn print_tuple(l: #(Int, Int)) -> String {
  "("
  <> pair.first(l) |> int.to_string
  <> ","
  <> pair.second(l) |> int.to_string
  <> ")"
}

pub fn print_dict(d: dict.Dict(Int, set.Set(Int))) -> String {
  let tree = string_tree.new() |> string_tree.append("{")
  dict.keys(d)
  |> list.fold(tree, fn(t, key) {
    case dict.get(d, key) {
      Ok(nums) ->
        string_tree.append(t, "\n" <> int.to_string(key) <> ": ")
        |> string_tree.append(utils.print_list(nums |> set.to_list))
      _ -> panic as "Key must exist"
    }
  })
  |> string_tree.append("\n}")
  |> string_tree.to_string
}

pub fn print_list(l: List(Int)) -> String {
  case l {
    [] -> "[]"
    [x] -> int.to_string(x)
    [x, y] -> int.to_string(x) <> "," <> int.to_string(y)
    _ -> {
      let tree =
        string_tree.new()
        |> string_tree.append(int.to_string(list.first(l) |> result.unwrap(0)))

      list.drop(l, 1)
      |> list.take(list.length(l) - 2)
      |> list.fold(tree, fn(t, x) {
        string_tree.append(t, "," <> int.to_string(x))
      })
      |> string_tree.append(",")
      |> string_tree.append(int.to_string(list.last(l) |> result.unwrap(0)))
      |> string_tree.to_string
    }
  }
}

pub fn print_tuple_list(l: List(#(Int, Int))) -> String {
  case l {
    [] -> "[]"
    [x] -> "[" <> print_tuple(x) <> "]"
    [x, y] -> "[" <> print_tuple(x) <> "," <> print_tuple(y) <> "]"
    _ -> {
      let tree =
        string_tree.new()
        |> string_tree.append("[")
        |> string_tree.append(print_tuple(
          list.first(l) |> result.unwrap(#(0, 0)),
        ))

      list.drop(l, 1)
      |> list.take(list.length(l) - 2)
      |> list.fold(tree, fn(t, x) {
        string_tree.append(t, "," <> print_tuple(x))
      })
      |> string_tree.append(",")
      |> string_tree.append(print_tuple(list.last(l) |> result.unwrap(#(0, 0))))
      |> string_tree.append("]")
      |> string_tree.to_string
    }
  }
}

pub fn read_file(filename: String) -> Result(String, Nil) {
  result.replace_error(simplifile.read(filename), Nil)
}

pub fn create_reports(content: String) -> Result(List(List(Int)), Nil) {
  string.trim(content)
  |> string.split("\n")
  |> list.map(fn(line) { string.trim(line) })
  |> list.map(fn(line) { string.split(line, " ") })
  |> list.map(fn(line) {
    list.map(line, fn(item) { int.parse(item) })
    |> result.all
  })
  |> result.all
}

pub fn create_list(content: String) -> Result(#(List(Int), List(Int)), Nil) {
  let split_lines: Result(List(#(String, String)), Nil) =
    string.split(string.trim(content), "\n")
    |> list.map(fn(line) { string.trim(line) })
    |> list.map(fn(line) { string.split_once(line, " ") })
    |> result.all

  split_lines
  |> result.map(fn(split_list: List(#(String, String))) {
    list.map(split_list, fn(tuple: #(String, String)) {
      #(
        int.parse(string.trim(pair.first(tuple))),
        int.parse(string.trim(pair.second(tuple))),
      )
    })
    |> list.unzip()
  })
  |> result.map(
    fn(two_lists: #(List(Result(Int, Nil)), List(Result(Int, Nil)))) {
      #(result.all(pair.first(two_lists)), result.all(pair.second(two_lists)))
    },
  )
  |> result.map(fn(x: #(Result(List(Int), Nil), Result(List(Int), Nil))) {
    case x {
      #(Error(Nil), _) -> Error(Nil)
      #(_, Error(Nil)) -> Error(Nil)
      #(Ok(a), Ok(b)) -> Ok(#(a, b))
    }
  })
  |> result.flatten()
}
