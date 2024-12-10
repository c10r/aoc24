import gleam/dict
import gleam/list
import gleam/order
import gleam/pair
import gleam/string

pub fn crossword_count(content: String, word: String) -> Int {
  let crossword = create_crossword(content)

  list.map(dict.keys(crossword), fn(info) { search(info, word, crossword) })
  |> list.fold(0, fn(x, y) { x + y })
}

pub fn crossword_x_count(content: String, word: String) -> Int {
  let crossword = create_crossword(content)

  list.map(dict.keys(crossword), fn(info) { search_x(info, word, crossword) })
  |> list.fold(0, fn(x, y) { x + y })
}

fn create_crossword(content: String) -> dict.Dict(#(Int, Int), String) {
  content
  |> string.split("\n")
  |> list.map(fn(line) { string.trim(line) })
  |> list.index_map(fn(line, row) {
    let characters = string.to_graphemes(line)
    list.index_map(characters, fn(char, col) { #(#(row, col), char) })
  })
  |> list.flatten
  |> dict.from_list
}

fn search_x(
  index: #(Int, Int),
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  let #(x, y) = #(pair.first(index), pair.second(index))
  // M.M
  // .A.
  // S.S
  let south_search =
    [
      search_southwest(x + string.length(word) - 1, y, word, crossword),
      search_southeast(x, y, word, crossword),
    ]
    |> coalesce_search
  // S.S
  // .A.
  // M.M
  let north_search =
    [
      search_northwest(
        x + string.length(word) - 1,
        y + string.length(word) - 1,
        word,
        crossword,
      ),
      search_northeast(x, y + string.length(word) - 1, word, crossword),
    ]
    |> coalesce_search
  // M.S
  // .A.
  // M.S
  let diag_search =
    [
      search_southeast(x, y, word, crossword),
      search_northeast(x, y + string.length(word) - 1, word, crossword),
    ]
    |> coalesce_search
  // S.M
  // .A.
  // S.M
  let rev_diag_search =
    [
      search_southwest(x + string.length(word) - 1, y, word, crossword),
      search_northwest(
        x + string.length(word) - 1,
        y + string.length(word) - 1,
        word,
        crossword,
      ),
    ]
    |> coalesce_search
  case south_search + north_search + diag_search + rev_diag_search {
    0 -> 0
    _ -> 1
  }
}

fn search(
  index: #(Int, Int),
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  let #(x, y) = #(pair.first(index), pair.second(index))
  [
    search_north(x, y, word, crossword),
    search_northeast(x, y, word, crossword),
    search_east(x, y, word, crossword),
    search_southeast(x, y, word, crossword),
    search_south(x, y, word, crossword),
    search_southwest(x, y, word, crossword),
    search_west(x, y, word, crossword),
    search_northwest(x, y, word, crossword),
  ]
  |> list.fold(0, fn(x, y) { x + y })
}

fn coalesce_search(result: List(Int)) -> Int {
  list.fold(result, 1, fn(x, y) {
    case x, y {
      1, 1 -> 1
      1, 0 -> 0
      _, _ -> 0
    }
  })
}

fn search_direction(
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
  next_index: fn(Int) -> #(Int, Int),
) -> Int {
  list.range(0, string.length(word) - 1)
  |> list.zip(string.to_graphemes(word))
  |> list.map(fn(index_letter_pair) {
    let index = pair.first(index_letter_pair)
    let letter = pair.second(index_letter_pair)

    let result = dict.get(crossword, next_index(index))
    case result {
      Error(Nil) -> 0
      Ok(new_letter) ->
        case string.compare(new_letter, letter) {
          order.Eq -> 1
          _ -> 0
        }
    }
  })
  |> coalesce_search
}

fn search_north(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x, y - index) })
}

fn search_northeast(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x + index, y - index) })
}

fn search_east(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x + index, y) })
}

fn search_southeast(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x + index, y + index) })
}

fn search_south(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x, y + index) })
}

fn search_southwest(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x - index, y + index) })
}

fn search_west(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x - index, y) })
}

fn search_northwest(
  x: Int,
  y: Int,
  word: String,
  crossword: dict.Dict(#(Int, Int), String),
) -> Int {
  search_direction(word, crossword, fn(index) { #(x - index, y - index) })
}
