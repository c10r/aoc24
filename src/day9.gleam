import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

pub fn checksum(content: String) -> Int {
  let disk_map = process_disk_map(content)

  let compacted =
    disk_map
    |> compact

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

fn compact_helper(disk_map: List(String), accum: List(String)) -> List(String) {
  // Manually find leftmost dot index
  let leftmost_dot =
    disk_map
    |> list.index_map(fn(x, idx) { #(x, idx) })
    |> list.find(fn(pair) { pair.0 == "." })
    |> result.map(fn(pair) { pair.1 })
    |> result.unwrap(-1)

  // Manually find rightmost non-dot index
  let rightmost_file =
    disk_map
    |> list.reverse
    |> list.index_map(fn(x, idx) { #(x, idx) })
    |> list.find(fn(pair) { pair.0 != "." })
    |> result.map(fn(pair) { list.length(disk_map) - 1 - pair.1 })
    |> result.unwrap(-1)

  case leftmost_dot, rightmost_file {
    dot, file if dot != -1 && file != -1 && dot < file -> {
      let file_value =
        disk_map
        |> list.drop(file)
        |> list.first
        |> result.unwrap("")

      let moved_map =
        disk_map
        |> list.take(dot)
        |> list.append([file_value])
        |> list.append(list.drop(disk_map, dot + 1))
        |> list.take(file)
        |> list.append(["."])
        |> list.append(list.drop(disk_map, file + 1))

      compact_helper(moved_map, accum)
    }
    _, _ -> disk_map
  }
}

// Does not add the remaining dots at the end
fn blah(disk_map: List(String), accum: List(String)) -> List(String) {
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
