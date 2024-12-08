import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

type Total =
  Int

type Operands =
  List(Int)

type Equation =
  #(Total, Operands)

pub fn total_calibration(content: String) -> Int {
  process_content(content)
  |> list.filter(fn(x) { result.is_ok(process_equation(x)) })
  |> list.map(process_equation)
  |> result.values
  |> list.fold(0, fn(x, y) { x + y })
}

fn process_equation(eq: Equation) -> Result(Int, Nil) {
  process_eq_helper(eq, 0)
}

fn process_eq_helper(eq: Equation, accum: Int) -> Result(Int, Nil) {
  let #(total, operands) = #(pair.first(eq), pair.second(eq))
  case operands {
    [] ->
      case accum == total {
        True -> Ok(total)
        _ -> Error(Nil)
      }
    [first, ..] ->
      result.or(
        process_eq_helper(
          #(total, list.drop(operands, 1)),
          first * get_multiplication_accum(accum),
        ),
        process_eq_helper(#(total, list.drop(operands, 1)), first + accum),
      )
  }
}

fn get_multiplication_accum(accum: Int) -> Int {
  case accum {
    0 -> 1
    _ -> accum
  }
}

fn process_content(content: String) -> List(Equation) {
  content
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) { process_line(line) })
}

fn process_line(content: String) -> Equation {
  let parts =
    content
    |> string.trim()
    |> string.split(":")

  case parts {
    [total, operands] -> {
      #(process_total(total), process_operands(operands))
    }
    _ -> panic as "Line must have exactly two parts, colon delimited"
  }
}

fn process_operands(content: String) -> Operands {
  let parts = content |> string.trim |> string.split(" ")
  parts
  |> list.map(fn(x) {
    case int.parse(x) {
      Ok(num) -> num
      _ -> panic as error_msg(x)
    }
  })
}

fn process_total(content: String) -> Int {
  case int.parse(content) {
    Ok(num) -> num
    _ -> panic as error_msg(content)
  }
}

fn error_msg(int_as_str: String) -> String {
  "Could not parse " <> int_as_str <> " to int"
}
