import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string

type Rules =
  List(#(Int, Int))

type PageOrder =
  dict.Dict(Int, Rules)

pub fn get_update_middles(updates: String, inputs: String) -> Int {
  let input_orders = create_input_rules(inputs) |> create_pageorder

  create_input_updates(updates)
  |> list.filter(fn(x) { is_update_valid(x, input_orders) })
  |> list.map(get_middle_update)
  |> result.all
  |> result.map(fn(middles) { list.fold(middles, 0, fn(x, y) { x + y }) })
  |> result.unwrap(-101)
}

fn get_middle_update(update: List(Int)) -> Result(Int, Nil) {
  let len = list.length(update)
  case len % 2 {
    n if n == 1 ->
      Ok(list.drop(update, len / 2) |> list.first) |> result.flatten
    _ -> Error(Nil)
  }
}

fn is_update_valid(update: List(Int), input_orders: PageOrder) -> Bool {
  let orders_for_update = get_order_for_update(update, input_orders)
  let index_dict = create_index_dict(update)

  orders_for_update
  |> dict.to_list
  |> list.map(fn(tuple) { pair.second(tuple) })
  |> list.flatten
  |> list.map(fn(rule) {
    let #(first, second) = #(
      dict.get(index_dict, pair.first(rule)),
      dict.get(index_dict, pair.second(rule)),
    )
    case first, second {
      Ok(x), Ok(y) -> {
        x < y
      }
      _, _ -> False
    }
  })
  |> list.fold(True, fn(x, y) { x && y })
}

fn create_index_dict(update: List(Int)) -> dict.Dict(Int, Int) {
  update
  |> list.index_map(fn(x, index) { #(x, index) })
  |> dict.from_list
}

/// Get only the rules for which _both_ elements of the tuple are present in the update
/// Example orders: [#(75,47), #(97,75), #(47,61), #(75,61), #(47,29), #(75,13), #(53,13)]
/// Example update: [75,47]
/// Example output: [75,47]
fn get_order_for_update(update: List(Int), orders: PageOrder) -> PageOrder {
  let update_set = set.from_list(update)

  orders
  |> dict.filter(fn(key, _) { set.contains(update_set, key) })
  |> dict.map_values(fn(_, value) {
    value
    |> list.filter(fn(tuple) {
      set.contains(update_set, pair.first(tuple))
      && set.contains(update_set, pair.second(tuple))
    })
  })
  |> dict.filter(fn(_, value) { list.length(value) > 0 })
}

fn create_pageorder(rules: Rules) -> PageOrder {
  rules
  |> list.map(fn(rule) {
    let #(x, y) = #(pair.first(rule), pair.second(rule))
    [#(x, rule), #(y, rule)]
  })
  |> list.flatten
  |> list.group(fn(item) { pair.first(item) })
  |> dict.map_values(fn(_, value: List(#(Int, #(Int, Int)))) {
    value |> list.map(fn(tuple) { pair.second(tuple) })
  })
}

fn create_input_rules(content: String) -> Rules {
  string.trim(content)
  |> string.split("\n")
  |> list.map(fn(line) {
    let parts =
      string.trim(line)
      |> string.split("|")
      |> list.map(fn(part) { string.trim(part) |> int.parse })

    case parts {
      [first, second] -> {
        case first, second {
          Ok(x), Ok(y) -> Ok(#(x, y))
          _, _ -> Error(Nil)
        }
      }
      _ -> Error(Nil)
    }
  })
  |> result.values
}

fn create_input_updates(content: String) -> List(List(Int)) {
  string.trim(content)
  |> string.split("\n")
  |> list.map(fn(line) {
    string.trim(line)
    |> string.split(",")
    |> list.map(fn(part) { string.trim(part) |> int.parse |> result.unwrap(-1) })
  })
}
