import gleam/int
import gleam/list
import gleam/result

import day2_part1

pub fn num_dampened_reports(reports: List(List(Int))) -> Int {
  reports
  |> list.filter(fn(r) { day2_part1.is_safe_report(r) || is_safe_dampened(r) })
  |> list.length
}

fn is_safe_dampened(report: List(Int)) -> Bool {
  helper(report, 0, True, 0) || helper(report, 0, False, 0)
}

fn helper(report: List(Int), index: Int, ascending: Bool, accum: Int) -> Bool {
  case accum {
    n if n > 1 -> False
    _ ->
      case report {
        [] -> True
        [_] -> True
        [first, second] -> cmp(first, second, ascending)
        [first, _, ..] -> {
          let length = list.length(report)
          case index, length {
            i, j if i < j - 1 -> {
              let x: Int = case i {
                0 -> first
                _ -> list.take(report, i + 1) |> list.last |> result.unwrap(0)
              }
              let y: Int =
                list.take(report, i + 2) |> list.last() |> result.unwrap(0)
              case cmp(x, y, ascending) {
                True -> helper(report, index + 1, ascending, accum)
                False ->
                  helper(rm_elem(report, index), 0, ascending, accum + 1)
                  || helper(rm_elem(report, index + 1), 0, ascending, accum + 1)
              }
            }
            _, _ -> True
          }
        }
      }
  }
}

fn cmp(x: Int, y: Int, ascending: Bool) -> Bool {
  case ascending {
    True -> y > x && max_diff(x, y)
    False -> x > y && max_diff(x, y)
  }
}

fn max_diff(x: Int, y: Int) -> Bool {
  let diff = int.absolute_value(x - y)
  diff > 0 && diff < 4
}

fn rm_elem(l: List(Int), index: Int) -> List(Int) {
  let length = list.length(l)
  case length, index {
    _, 0 -> list.drop(l, 1)
    x, y if x - y == 1 -> list.take(l, x - 1)
    _, _ -> list.append(list.take(l, index), list.drop(l, index + 1))
  }
}
