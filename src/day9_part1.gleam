import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub fn checksum(content: String) -> Int {
  let disk_map = process_disk_map(content)

  io.println(string.join(disk_map, ""))

  let compacted =
    disk_map
    |> compact

  io.println(string.join(compacted, ""))

  compacted
  |> list.map(int.parse)
  |> result.values
  |> list.index_fold(0, fn(accum, new_elem, index) {
    accum + { index * new_elem }
  })
}

fn compact(disk_map: List(String)) -> List(String) {
  case disk_map {
    [] | [_] -> disk_map
    _ -> compact_helper(disk_map, list.new())
  }
}

// Does not add the remaining dots at the end
fn compact_helper(disk_map: List(String), accum: List(String)) -> List(String) {
  case disk_map {
    [] -> accum
    _ -> {
      case list.first(disk_map) {
        Ok(char) ->
          case char {
            "." -> {
              let padding =
                list.drop(disk_map, 1)
                |> list.reverse
                |> list.drop_while(fn(char) { char == "." })
              case padding {
                [] -> accum
                [first, ..rest] ->
                  compact_helper(
                    list.reverse(rest),
                    list.append(accum, [first]),
                  )
              }
            }
            _ ->
              compact_helper(list.drop(disk_map, 1), list.append(accum, [char]))
          }
        _ -> panic as "List must not be empty"
      }
    }
  }
}

fn process_disk_map(content: String) -> List(String) {
  content
  |> string.trim
  |> string.to_graphemes
  |> list.index_map(fn(char, index) {
    case int.parse(char) {
      Ok(num) -> {
        get_char(index, num) |> string.to_graphemes
      }
      _ -> panic as "Corrupt input file"
    }
  })
  |> list.flatten
}

fn get_char(index: Int, times: Int) -> String {
  case index % 2 {
    0 -> string.repeat(int.to_string(index / 2), times)
    _ -> string.repeat(".", times)
  }
}
