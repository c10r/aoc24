import gleam/int
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string

pub fn multiply(corrupt_input: String) -> Int {
  let pattern = regex.from_string("(.*?(mul\\([0-9]+,[0-9]+\\)).*?)*?")
  let multiply_matches: List(String) =
    pattern
    |> result.map(fn(pat) { regex.scan(pat, corrupt_input) })
    |> result.replace_error(Nil)
    |> result.map(fn(matches: List(regex.Match)) {
      matches
      |> list.map(fn(match) { extract_submatch(match) })
      |> list.map(fn(res) { result.unwrap(res, option.None) })
    })
    |> result.unwrap(list.new())
    |> list.filter(option.is_some)
    |> list.map(fn(x) { option.unwrap(x, "") })

  multiply_matches
  |> list.map(multiply_string)
  |> result.all
  |> result.map(fn(numbers) { numbers |> list.fold(0, fn(x, y) { x + y }) })
  |> result.unwrap(-1)
}

fn multiply_string(str: String) -> Result(Int, Nil) {
  let left: Result(Int, Nil) =
    str
    |> string.split(",")
    |> list.first
    |> result.map(fn(x) { string.split(x, "(") })
    |> result.map(list.last)
    |> result.flatten
    |> result.map(int.parse)
    |> result.flatten

  let right: Result(Int, Nil) =
    str
    |> string.split(",")
    |> list.last
    |> result.map(fn(x) { string.split(x, ")") })
    |> result.map(list.first)
    |> result.flatten
    |> result.map(int.parse)
    |> result.flatten

  case left, right {
    Ok(x), Ok(y) -> Ok(x * y)
    _, _ -> Error(Nil)
  }
}

fn extract_submatch(match: regex.Match) -> Result(option.Option(String), Nil) {
  case match {
    regex.Match(_, []) -> Error(Nil)
    regex.Match(_, [_, ..] as submatches) -> list.last(submatches)
  }
}
