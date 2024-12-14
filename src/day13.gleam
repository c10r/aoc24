import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

type Coordinate =
  #(Int, Int)

type Puzzle {
  Puzzle(a: Coordinate, b: Coordinate, prize: Coordinate)
}

const error = 10_000_000_000_000

pub fn fewest_tokens(content: String, correct_error: Bool) -> Int {
  create_puzzles(content, correct_error)
  |> list.map(solve_puzzle)
  |> result.values
  |> list.fold(0, fn(x, y) { x + y })
}

fn solve_puzzle(puzzle: Puzzle) -> Result(Int, Nil) {
  let #(xa, ya) = puzzle.a
  let #(xb, yb) = puzzle.b
  let #(xp, yp) = puzzle.prize

  let det = { xa * yb } - { xb * ya }
  let det_a = { xp * yb } - { xb * yp }
  let det_b = { xa * yp } - { xp * ya }

  // 0 det means no solution
  case det {
    0 -> Error(Nil)
    _ -> {
      case divides_evenly(det_a, det), divides_evenly(det_b, det) {
        Ok(a), Ok(b) -> {
          case a < 0 || b < 0 {
            True -> Error(Nil)
            False -> Ok({ 3 * a } + b)
          }
        }
        _, _ -> Error(Nil)
      }
    }
  }
}

fn divides_evenly(x: Int, d: Int) -> Result(Int, Nil) {
  case x % d {
    0 -> Ok(x / d)
    _ -> Error(Nil)
  }
}

fn create_puzzles(content: String, correct_error: Bool) -> List(Puzzle) {
  let lines = string.trim(content) |> string.split("\n")
  parse_puzzle(lines, [], correct_error) |> pair.first
}

fn parse_puzzle(
  lines: List(String),
  puzzles: List(Puzzle),
  correct_error: Bool,
) -> #(List(Puzzle), List(String)) {
  case lines {
    [] -> #(puzzles, [])
    [_, _, _, _, ..rest] -> {
      let button_a =
        list.find(lines, fn(line) { string.starts_with(line, "Button A") })
      let button_b =
        list.find(lines, fn(line) { string.starts_with(line, "Button B") })
      let prize =
        list.find(lines, fn(line) { string.starts_with(line, "Prize") })
      case button_a, button_b, prize {
        _, _, Error(_) -> panic as "Malformed Input- Could not find prize"
        _, Error(_), _ -> panic as "Malformed Input- Could not find button B"
        Error(_), _, _ -> panic as "Malformed Input- Could not find button A"
        Ok(a), Ok(b), Ok(p) ->
          parse_puzzle(
            rest,
            list.append(puzzles, [
              Puzzle(
                parse_button(a),
                parse_button(b),
                parse_prize(p, correct_error),
              ),
            ]),
            correct_error,
          )
      }
    }
    _ -> panic as "Malformed Input - Must have at least a 4 line block"
  }
}

fn parse_prize(line: String, correct_error: Bool) -> Coordinate {
  case string.split(line, ":") {
    [_, tail] ->
      case string.split(tail, ",") {
        [x, y] ->
          case correct_error {
            True -> #(
              extract_coord(x, "=") + error,
              extract_coord(y, "=") + error,
            )
            False -> #(extract_coord(x, "="), extract_coord(y, "="))
          }
        _ -> panic as "Malformed input- Prize line must contain ,"
      }
    _ -> panic as "Malformed input- Prize line must contain :"
  }
}

fn parse_button(line: String) -> Coordinate {
  case string.split(line, ":") {
    [_, tail] ->
      case string.split(tail, ",") {
        [x, y] -> #(extract_coord(x, "+"), extract_coord(y, "+"))
        _ -> panic as "Malformed input- Line must contain ,"
      }
    _ -> panic as "Malformed input- Line must contain :"
  }
}

fn extract_coord(var_text: String, token: String) -> Int {
  case string.trim(var_text) |> string.split(token) {
    [_, num] ->
      case int.parse(num) {
        Ok(n) -> n
        _ -> panic as "Malformed input- Could not parse int"
      }
    _ -> panic as "Malformed input- Button lines must have + or ="
  }
}
