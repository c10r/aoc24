import gleam/dict
import gleam/list
import gleam/set
import gleam/string

type Name =
  String

type Row =
  Int

type Column =
  Int

type Coordinate =
  #(Row, Column)

type CoordinateSet =
  set.Set(Coordinate)

type Regions =
  dict.Dict(Name, List(CoordinateSet))

pub fn total_price(content: String) -> Int {
  parse_regions(content)
  |> dict.map_values(fn(_, value) {
    list.fold(value, 0, fn(accum, coords) {
      accum + { calculate_area(coords) * calculate_perimeter(coords) }
    })
  })
  |> dict.values
  |> list.fold(0, fn(x, y) { x + y })
}

pub fn total_price_bulk_discount(content: String) -> Int {
  parse_regions(content)
  |> dict.map_values(fn(_, value) {
    list.fold(value, 0, fn(accum, coords) {
      accum + { calculate_area(coords) * calculate_perimeter_discount(coords) }
    })
  })
  |> dict.values
  |> list.fold(0, fn(x, y) { x + y })
}

fn calculate_perimeter_discount(coords: CoordinateSet) -> Int {
  discount_perimeter_helper(set.to_list(coords), coords, 0)
}

fn discount_perimeter_helper(
  remaining: List(Coordinate),
  region_map: CoordinateSet,
  corners: Int,
) -> Int {
  case remaining {
    [] -> corners
    [first, ..rest] ->
      discount_perimeter_helper(
        rest,
        region_map,
        corners + num_corners(first, region_map),
      )
  }
}

fn num_corners(coord: Coordinate, map: CoordinateSet) -> Int {
  let topleft =
    !set.contains(map, top(coord)) && !set.contains(map, left(coord))
  let bottomleft =
    !set.contains(map, bottom(coord)) && !set.contains(map, left(coord))
  let topright =
    !set.contains(map, top(coord)) && !set.contains(map, right(coord))
  let bottomright =
    !set.contains(map, bottom(coord)) && !set.contains(map, right(coord))

  let innertopleft =
    set.contains(map, top(coord))
    && set.contains(map, left(coord))
    && !set.contains(map, #(coord.0 - 1, coord.1 - 1))
  let innertopright =
    set.contains(map, top(coord))
    && set.contains(map, right(coord))
    && !set.contains(map, #(coord.0 - 1, coord.1 + 1))
  let innerbottomleft =
    set.contains(map, bottom(coord))
    && set.contains(map, left(coord))
    && !set.contains(map, #(coord.0 + 1, coord.1 - 1))
  let innerbottomright =
    set.contains(map, bottom(coord))
    && set.contains(map, right(coord))
    && !set.contains(map, #(coord.0 + 1, coord.1 + 1))

  [
    topleft,
    bottomleft,
    topright,
    bottomright,
    innertopleft,
    innertopright,
    innerbottomleft,
    innerbottomright,
  ]
  |> list.count(fn(x) { x })
}

fn right(coord: Coordinate) -> Coordinate {
  #(coord.0, coord.1 + 1)
}

fn left(coord: Coordinate) -> Coordinate {
  #(coord.0, coord.1 - 1)
}

fn top(coord: Coordinate) -> Coordinate {
  #(coord.0 - 1, coord.1)
}

fn bottom(coord: Coordinate) -> Coordinate {
  #(coord.0 + 1, coord.1)
}

fn calculate_perimeter(coords: CoordinateSet) -> Int {
  perimeter_helper(set.to_list(coords), coords, 0)
}

fn perimeter_helper(
  remaining: List(Coordinate),
  region_map: CoordinateSet,
  accum: Int,
) -> Int {
  case remaining {
    [] -> accum
    [first, ..rest] -> {
      let new_perimeter = additional_perimeter(first, region_map)
      perimeter_helper(rest, region_map, accum + new_perimeter)
    }
  }
}

fn additional_perimeter(coord: Coordinate, rest: CoordinateSet) -> Int {
  let #(x, y) = #(coord.0, coord.1)
  let neighbors = [
    set.contains(rest, #(x - 1, y)),
    set.contains(rest, #(x + 1, y)),
    set.contains(rest, #(x, y - 1)),
    set.contains(rest, #(x, y + 1)),
  ]
  list.fold(neighbors, 0, fn(accum, next) {
    case next {
      False -> accum + 1
      True -> accum
    }
  })
}

fn calculate_area(coords: CoordinateSet) {
  set.size(coords)
}

fn parse_regions(content: String) -> Regions {
  string.trim(content)
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    string.trim(line)
    |> string.to_graphemes
    |> list.index_map(fn(name, col) { #(name, #(row, col)) })
  })
  |> list.flatten
  |> list.group(fn(tup) { tup.0 })
  |> dict.map_values(fn(_, value) {
    let coord_set = list.map(value, fn(tup) { tup.1 }) |> set.from_list
    partition_contiguous_regions(set.to_list(coord_set), coord_set, list.new())
  })
}

fn partition_contiguous_regions(
  queue: List(Coordinate),
  full_region: CoordinateSet,
  accum: List(CoordinateSet),
) -> List(CoordinateSet) {
  case queue {
    [] -> accum
    [next, ..rest] -> {
      let subregion = bfs([next], full_region, set.new())
      let new_accum = list.append(accum, [subregion])
      partition_contiguous_regions(
        list.filter(rest, fn(coord) {
          list.fold(new_accum, True, fn(accum, new_set) {
            accum && !set.contains(new_set, coord)
          })
        }),
        full_region,
        new_accum,
      )
    }
  }
}

fn bfs(
  queue: List(Coordinate),
  region_map: CoordinateSet,
  accum: CoordinateSet,
) -> CoordinateSet {
  case queue {
    [] -> accum
    [next, ..rest] -> {
      case set.contains(accum, next) {
        True -> bfs(rest, region_map, accum)
        False -> {
          let new_neighbors =
            get_all_neighbors(next, region_map)
            |> list.filter(fn(coord) { !set.contains(accum, coord) })
          bfs(
            list.append(rest, new_neighbors),
            region_map,
            set.insert(accum, next),
          )
        }
      }
    }
  }
}

fn get_all_neighbors(
  coord: Coordinate,
  region_map: CoordinateSet,
) -> List(Coordinate) {
  let #(x, y) = #(coord.0, coord.1)
  [#(x + 1, y), #(x - 1, y), #(x, y + 1), #(x, y - 1)]
  |> list.filter(fn(coord) { set.contains(region_map, coord) })
}
