import gleam/dict
import gleam/int
import gleam/list
import gleam/order
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
  |> result.unwrap(-1)
}

pub fn get_incorrect_update_middles(updates: String, inputs: String) -> Int {
  let input_orders = create_input_rules(inputs) |> create_pageorder

  create_input_updates(updates)
  |> list.filter(fn(x) { !is_update_valid(x, input_orders) })
  |> list.map(fn(u) { fix_update(u, get_order_for_update(u, input_orders)) })
  |> list.map(get_middle_update)
  |> result.all
  |> result.map(fn(middles) { list.fold(middles, 0, fn(x, y) { x + y }) })
  |> result.unwrap(-1)
}

fn fix_update(update: List(Int), orders: PageOrder) -> List(Int) {
  let update_index = create_index_dict(update)
  let order_list = dict.to_list(orders) |> list.map(pair.second) |> list.flatten

  fix_update_helper(update_index, order_list, 0, list.length(update))
  |> result.unwrap(dict.new())
  |> dict.to_list
  |> list.sort(fn(tup1, tup2) {
    let index1 = tup1.1
    let index2 = tup2.1

    case index1 - index2 {
      n if n > 0 -> order.Gt
      n if n < 0 -> order.Lt
      _ -> order.Eq
    }
  })
  |> list.map(pair.first)
}

// Given the following update: [61,13,29]
// Here are the relevant rules: [#(61,13), #(29,13), #(61,29)]
// Create an index dict: { 61: 0, 13: 1, 29: 2 }
// Update indices to satisfy each rule, one at a time
fn fix_update_helper(
  update: dict.Dict(Int, Int),
  rules: Rules,
  rule_index: Int,
  current_max_index: Int,
) -> Result(dict.Dict(Int, Int), Nil) {
  let num_rules = list.length(rules)
  case num_rules - rule_index - 1 {
    n if n == 0 -> Ok(update)
    _ -> {
      let new_rule = list.drop(rules, rule_index) |> list.take(1)
      case new_rule {
        [rule] -> {
          let #(first, second) = #(
            dict.get(update, rule.0),
            dict.get(update, rule.1),
          )
          case first, second {
            Ok(x), Ok(y) -> {
              case x < y {
                True ->
                  fix_update_helper(
                    update,
                    rules,
                    rule_index + 1,
                    current_max_index,
                  )
                False -> {
                  let key_to_update =
                    update
                    |> dict.filter(fn(_, value) { value == y })
                    |> dict.keys
                    |> list.first
                  case key_to_update {
                    Ok(new_key) -> {
                      let new_update =
                        dict.upsert(update, new_key, fn(_) {
                          current_max_index + 1
                        })
                      fix_update_helper(
                        new_update,
                        rules,
                        0,
                        current_max_index + 1,
                      )
                    }
                    _ -> Error(Nil)
                  }
                }
              }
            }
            _, _ -> Error(Nil)
          }
        }
        _ -> Ok(update)
      }
    }
  }
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
  |> list.map(pair.second)
  |> list.flatten
  |> list.map(fn(rule) {
    let #(first, second) = #(
      dict.get(index_dict, rule.0),
      dict.get(index_dict, rule.1),
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
      set.contains(update_set, tuple.0) && set.contains(update_set, tuple.1)
    })
  })
  |> dict.filter(fn(_, value) { list.length(value) > 0 })
}

fn create_pageorder(rules: Rules) -> PageOrder {
  rules
  |> list.map(fn(rule) {
    let #(x, y) = #(rule.0, rule.1)
    [#(x, rule), #(y, rule)]
  })
  |> list.flatten
  |> list.group(fn(item) { item.0 })
  |> dict.map_values(fn(_, value: List(#(Int, #(Int, Int)))) {
    value |> list.map(pair.second)
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
