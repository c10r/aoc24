import gleam/int
import gleam/list
import gleam/pair

pub fn num_safe_reports(reports: List(List(Int))) -> Int {
  reports
  |> list.filter(fn(r) { is_safe_report(r) })
  |> list.length
}

fn is_safe_report(report: List(Int)) -> Bool {
  case report {
    [first, second, ..] -> {
      case first - second {
        n if n > 0 -> all_decreasing(report)
        n if n < 0 -> all_increasing(report)
        _ -> False
      }
    }
    _ -> True
  }
}

fn compare_pairs(report: List(Int), cmp: fn(Int, Int) -> Bool) -> Bool {
  create_pairs(report)
  |> list.map(fn(p) {
    let x = pair.first(p)
    let y = pair.second(p)
    cmp(x, y) && max_diff(x, y)
  })
  |> list.all(fn(bool) { bool })
}

fn max_diff(x: Int, y: Int) -> Bool {
  let diff = int.absolute_value(x - y)
  diff > 0 && diff < 4
}

fn create_pairs(report: List(Int)) -> List(#(Int, Int)) {
  report |> list.zip(list.drop(report, 1))
}

fn all_increasing(report: List(Int)) -> Bool {
  compare_pairs(report, fn(x, y) { y > x })
}

fn all_decreasing(report: List(Int)) -> Bool {
  compare_pairs(report, fn(x, y) { y < x })
}
