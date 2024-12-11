import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

type Block {
  Empty
  File(id: Int)
}

type DiskMap =
  List(Block)

pub fn checksum(content: String) -> Int {
  content
  |> string.trim
  |> create_diskmap
  |> compact
  |> calculate
}

fn compact(map: DiskMap) -> DiskMap {
  case map {
    [] | [_] -> map
    _ -> compact_helper(map, list.new())
  }
}

fn compact_helper(map: DiskMap, accum: DiskMap) -> DiskMap {
  case map {
    [] -> accum
    [next, ..rest] ->
      case next {
        File(_) -> compact_helper(rest, list.append(accum, [next]))
        Empty -> {
          let new_rev =
            list.drop_while(list.reverse(map), fn(b) {
              case b {
                Empty -> True
                _ -> False
              }
            })
          case list.first(new_rev) {
            Ok(f) -> {
              let new_map =
                list.drop(new_rev, 1) |> list.reverse |> list.drop(1)
              compact_helper(new_map, list.append(accum, [f]))
            }
            _ -> accum
          }
        }
      }
  }
}

fn calculate(map: DiskMap) -> Int {
  list.fold(map, #(0, 0), fn(accum, element) {
    case element {
      Empty -> accum
      File(id) -> #(accum.0 + { id * accum.1 }, accum.1 + 1)
    }
  })
  |> pair.first
}

fn create_diskmap(content: String) -> DiskMap {
  string.trim(content)
  |> string.to_graphemes
  |> list.map(int.parse)
  |> result.values
  |> list.index_map(fn(num, index) {
    case index % 2 {
      0 -> list.repeat(File(index / 2), num)
      _ -> list.repeat(Empty, num)
    }
  })
  |> list.flatten
}
