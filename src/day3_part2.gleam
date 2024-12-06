import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regex
import gleam/result
import gleam/string

pub fn multiply(corrupt_input: String) -> Int {
  let pattern =
    regex.from_string(
      "(.*?((mul\\([0-9]+,[0-9]+\\))|(do\\(\\))|(don't\\(\\)).*?))*?",
    )
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

  helper(multiply_matches, 0, True)
}

fn helper(matches: List(String), accum: Int, on: Bool) -> Int {
  case matches {
    [] -> accum
    [first, ..] -> {
      let rest = list.drop(matches, 1)
      case on {
        False ->
          case first {
            "do()" -> helper(rest, accum, True)
            _ -> helper(rest, accum, on)
          }
        True ->
          case first {
            "don't()" -> helper(rest, accum, False)
            "do" -> helper(rest, accum, True)
            _ -> {
              let multiple = multiply_string(first) |> result.unwrap(0)
              helper(rest, accum + multiple, on)
            }
          }
      }
    }
  }
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
