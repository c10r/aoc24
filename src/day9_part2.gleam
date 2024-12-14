import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/string_tree

type Block {
  Empty(size: Int)
  File(id: Int, size: Int)
}

type Index =
  Int

type DiskMap =
  List(Block)

type IndexedDiskMap =
  List(#(Block, Index))

pub fn checksum(content: String) -> Int {
  let compact_map =
    content
    |> string.trim
    |> create_diskmap
    |> compact

  io.println(print_diskmap(compact_map))

  compact_map |> calculate
}

fn compact(map: DiskMap) -> DiskMap {
  case map {
    [] | [_] -> map
    _ -> {
      let indexed_map =
        list.index_map(map, fn(block, index) { #(block, index) })
      compact_helper(
        indexed_map,
        list.reverse(indexed_map),
        list.new(),
        set.new(),
      )
    }
  }
}

fn compact_helper(
  map: IndexedDiskMap,
  rev_map: IndexedDiskMap,
  accum: DiskMap,
  ignored_indices: set.Set(Index),
) -> DiskMap {
  io.println(string.repeat("-", 42))
  io.println("map: " <> print_indexed_diskmap(map))
  io.println("rev: " <> print_indexed_diskmap(rev_map))
  io.println("acc: " <> print_diskmap(accum))
  io.println(string.repeat("-", 42))

  case map {
    [] -> accum
    [next, ..rest] ->
      case next {
        #(file_or_empty, index) ->
          case set.contains(ignored_indices, index) {
            True -> compact_helper(rest, rev_map, accum, ignored_indices)
            _ ->
              case file_or_empty {
                File(_, _) ->
                  compact_helper(
                    rest,
                    rev_map,
                    list.append(accum, [file_or_empty]),
                    ignored_indices,
                  )
                Empty(empty_size) -> {
                  let new_rev =
                    list.drop_while(rev_map, fn(element) {
                      case element.0 {
                        Empty(_) -> True
                        File(_, file_size) -> file_size > empty_size
                      }
                    })
                  case new_rev {
                    [] ->
                      compact_helper(
                        rest,
                        new_rev,
                        list.append(accum, [file_or_empty]),
                        ignored_indices,
                      )
                    [next_rev, ..rev_rest] -> {
                      let next_rev_size = case next_rev.0 {
                        Empty(size) -> size
                        File(_, size) -> size
                      }
                      let new_map = case empty_size > next_rev_size {
                        False -> rest
                        True ->
                          list.append(
                            [#(Empty(empty_size - next_rev_size), index)],
                            rest,
                          )
                      }
                      compact_helper(
                        new_map,
                        rev_rest,
                        list.append(accum, [next_rev.0]),
                        set.insert(ignored_indices, next_rev.1),
                      )
                    }
                  }
                }
              }
          }
      }
  }
}

fn calculate(map: DiskMap) -> Int {
  list.fold(map, #(0, 0), fn(accum, element) {
    case element {
      Empty(size) -> #(accum.0, accum.1 + size)
      File(id, size) -> {
        let new_tot =
          list.range(0, size - 1)
          |> list.map(fn(x) { { x + accum.1 } * id })
          |> list.fold(0, fn(x, y) { x + y })
        #(new_tot, accum.1 + size)
      }
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
      0 -> File(index / 2, num)
      _ -> Empty(num)
    }
  })
}

fn print_indexed_diskmap(map: IndexedDiskMap) -> String {
  let tree = string_tree.new()

  list.fold(map, tree, fn(t, elem) {
    case elem.0 {
      Empty(size) -> string_tree.append(t, string.repeat(".", size))
      File(id, size) ->
        string_tree.append(t, string.repeat(int.to_string(id), size))
    }
  })
  |> string_tree.to_string()
}

fn print_diskmap(map: DiskMap) -> String {
  let tree = string_tree.new()

  list.fold(map, tree, fn(t, block) {
    case block {
      Empty(size) -> string_tree.append(t, string.repeat(".", size))
      File(id, size) ->
        string_tree.append(t, string.repeat(int.to_string(id), size))
    }
  })
  |> string_tree.to_string()
}
