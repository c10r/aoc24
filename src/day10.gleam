import gleam/dict
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string

type Elevation =
  Int

type Row =
  Int

type Column =
  Int

type Coordinate =
  #(Row, Column)

type Map =
  dict.Dict(Coordinate, Elevation)

type Path =
  set.Set(Coordinate)

// Part 1
pub fn trailhead_scores(content: String) -> Int {
  let map = create_map(content)
  let trailheads = get_trailheads(map)
  trailheads
  |> list.map(fn(head) { calculate_trailhead_score(head, map) })
  |> list.fold(0, fn(x, y) { x + y })
}

// Part 2
pub fn trailhead_rating(content: String) -> Int {
  let map = create_map(content)
  let trailheads = get_trailheads(map)
  trailheads
  |> list.map(fn(head) { calculate_trailhead_rating(head, map) })
  |> list.fold(0, fn(x, y) { x + y })
}

fn calculate_trailhead_rating(trailhead: Coordinate, map: Map) -> Int {
  rating_helper(trailhead, map, set.new(), list.new()) |> list.length
}

fn rating_helper(
  current: Coordinate,
  map: Map,
  current_path: Path,
  found_paths: List(Path),
) -> List(Path) {
  case dict.get(map, current) {
    Ok(9) -> list.append(found_paths, [set.insert(current_path, current)])
    Ok(_) -> {
      let next = next_coordinates(current, map, current_path)
      let updated_path = set.insert(current_path, current)
      list.fold(next, found_paths, fn(accum, next_coord) {
        rating_helper(next_coord, map, updated_path, accum)
      })
    }
    _ -> found_paths
  }
}

fn calculate_trailhead_score(trailhead: Coordinate, map: Map) -> Int {
  score_helper(trailhead, map, set.new(), set.new()) |> set.size
}

fn score_helper(
  current: Coordinate,
  map: Map,
  current_path: Path,
  found_ends: set.Set(Coordinate),
) -> set.Set(Coordinate) {
  case dict.get(map, current) {
    Ok(9) -> set.insert(found_ends, current)
    Ok(_) -> {
      let next = next_coordinates(current, map, current_path)
      let updated_path = set.insert(current_path, current)
      list.fold(next, found_ends, fn(accum, next_coord) {
        score_helper(next_coord, map, updated_path, accum)
      })
    }
    _ -> found_ends
  }
}

fn next_coordinates(
  current: Coordinate,
  map: Map,
  current_path: Path,
) -> List(Coordinate) {
  [
    #(current.0 - 1, current.1),
    #(current.0 + 1, current.1),
    #(current.0, current.1 - 1),
    #(current.0, current.1 + 1),
  ]
  |> list.filter(fn(coord) {
    case dict.get(map, coord) {
      Ok(num) ->
        case dict.get(map, current) {
          Ok(current_num) -> num - current_num == 1
          _ -> False
        }
      _ -> False
    }
  })
  |> list.filter(fn(coord) { !set.contains(current_path, coord) })
}

fn get_trailheads(map: Map) -> List(Coordinate) {
  dict.to_list(map)
  |> list.filter(fn(tup) { pair.second(tup) == 0 })
  |> list.map(fn(tup) { pair.first(tup) })
}

fn create_map(content: String) -> Map {
  string.trim(content)
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    string.trim(line)
    |> string.to_graphemes
    |> list.index_map(fn(elevation, col) {
      case int.parse(elevation) {
        Ok(num) -> #(#(row, col), Ok(num))
        _ -> #(#(row, col), Error(Nil))
      }
    })
  })
  |> list.flatten
  |> list.filter(fn(element) { result.is_ok(pair.second(element)) })
  |> list.map(fn(element) {
    #(pair.first(element), result.unwrap(pair.second(element), -1))
  })
  |> dict.from_list
}
