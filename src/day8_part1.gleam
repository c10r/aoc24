import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string

pub type Row =
  Int

pub type Column =
  Int

pub type Coordinate =
  #(Row, Column)

pub type CityMap =
  dict.Dict(Coordinate, String)

pub type StationMap =
  dict.Dict(String, List(Coordinate))

pub fn antinode_count(content: String) -> Int {
  let city_map = create_city_map(content)
  let station_map = create_station_map(city_map)

  dict.values(station_map)
  |> list.filter(fn(coords) { list.length(coords) > 1 })
  |> list.map(fn(station) { antinodes_for_station(station, city_map) })
  |> list.fold(set.new(), fn(accum, new_list) {
    new_list |> list.fold(accum, fn(accum, coord) { set.insert(accum, coord) })
  })
  |> set.size
}

fn antinodes_for_station(
  coords: List(Coordinate),
  city_map: CityMap,
) -> List(Coordinate) {
  coords
  |> list.combination_pairs
  |> list.map(fn(combination_pair) {
    let #(c1, c2) = #(combination_pair.0, combination_pair.1)
    let #(x1, y1) = #(c1.0, c1.1)
    let #(x2, y2) = #(c2.0, c2.1)
    let xdiff = x1 - x2
    let ydiff = y1 - y2
    [#(x1 + xdiff, y1 + ydiff), #(x2 - xdiff, y2 - ydiff)]
  })
  |> list.flatten
  |> list.filter(fn(coord) { result.is_ok(dict.get(city_map, coord)) })
}

pub fn create_station_map(city_map: CityMap) -> StationMap {
  dict.filter(city_map, fn(_, value) { value != "." })
  |> dict.to_list
  |> list.fold(dict.new(), fn(accum_dict, station) {
    let #(coord, s) = #(station.0, station.1)
    dict.upsert(accum_dict, s, fn(val) {
      case val {
        option.Some(vals) -> list.append(vals, [coord])
        option.None -> [coord]
      }
    })
  })
}

pub fn create_city_map(content: String) -> CityMap {
  content
  |> string.trim
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    line
    |> string.trim
    |> string.to_graphemes
    |> list.index_map(fn(node, col) { #(#(row, col), node) })
  })
  |> list.flatten
  |> dict.from_list
}
