import gleam/dict
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

type Cache =
  dict.Dict(#(Stones, Int), Stones)

pub fn num_stones(content: String, num_blink: Int) -> Int {
  let stones = parse_content(content)
  let result_stones = blink_with_memo(stones, num_blink, dict.new())

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

fn blink_with_memo(stones: Stones, times: Int, cache: Cache) -> Stones {
  io.println("level: " <> int.to_string(times))
  case times {
    0 -> stones
    _ -> {
      let cache_key = #(stones, times)

      case dict.get(cache, cache_key) {
        Ok(cached_result) -> cached_result
        Error(Nil) -> {
          let new_stones = blink_once(stones)
          let result = blink_with_memo(new_stones, times - 1, cache)

          result
        }
      }
    }
  }
}

fn blink_once(stones: Stones) -> Stones {
  list.map(stones, process_stone) |> list.flatten
}

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
