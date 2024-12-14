import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/string_tree

type Stone =
  Int

type Stones =
  List(Int)

pub fn num_stones(content: String, num_blink: Int) -> Int {
  let stones = parse_content(content)
  let result_stones = blink(stones, num_blink)

  io.println(print_stones(result_stones))

  result_stones |> list.length
}

fn print_stones(stones: Stones) -> String {
  let tree = string_tree.new()
  list.fold(stones, tree, fn(t, stone) {
    string_tree.append(t, int.to_string(stone) <> " ")
  })
  |> string_tree.to_string
}

fn blink(stones: Stones, times: Int) -> Stones {
  case times {
    0 -> stones
    _ -> blink(blink_once(stones), times - 1)
  }
}

fn blink_once(stones: Stones) -> Stones {
  list.map(stones, process_stone) |> list.flatten
}

// If 0, replaced by 1.
// If even number of digits, replaced by two stones. Left half of digits on the new left stone,
// and right half on the new right stone. (Don't keep leading zeroes: 1000 would become stones 10 and 0.)
// Else, old number multiplied by 2024
fn process_stone(stone: Stone) -> Stones {
  case stone {
    0 -> [1]
    _ -> {
      let stone_str = int.to_string(stone)
      case string.length(stone_str) % 2 {
        0 -> {
          let halfway = string.length(stone_str) / 2
          let first_half = string.slice(stone_str, 0, halfway)
          let second_half = string.slice(stone_str, halfway, halfway)
          [first_half, second_half] |> list.map(int.parse) |> result.values
        }
        _ -> [stone * 2024]
      }
    }
  }
}

fn parse_content(content: String) -> Stones {
  string.trim(content)
  |> string.split(" ")
  |> list.map(int.parse)
  |> result.values
}
