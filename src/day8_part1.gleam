import gleam/dict
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/set
import gleam/string

import utils

type Row =
  Int

type Column =
  Int

type Coordinate =
  #(Row, Column)

type CityMap =
  dict.Dict(Coordinate, String)

type StationMap =
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

pub fn antinode_count_part_2(content: String) -> Int {
  let city_map = create_city_map(content)
  let station_map = create_station_map(city_map)

  dict.values(station_map)
  |> list.filter(fn(coords) { list.length(coords) > 1 })
  |> list.map(fn(station) { antinode_part_2(station, city_map) })
  |> list.fold(set.new(), fn(accum, new_list) {
    new_list |> list.fold(accum, fn(accum, coord) { set.insert(accum, coord) })
  })
  |> set.size
}

fn antinode_part_2(
  coords: List(Coordinate),
  city_map: CityMap,
) -> List(Coordinate) {
  coords
  |> list.combination_pairs
  |> list.map(fn(combination_pair) {
    let #(c1, c2) = #(
      pair.first(combination_pair),
      pair.second(combination_pair),
    )
    let #(x1, y1) = #(pair.first(c1), pair.second(c1))
    let #(x2, y2) = #(pair.first(c2), pair.second(c2))
    let xdiff = x1 - x2
    let ydiff = y1 - y2
    [
      antinode_part_2_helper(#(x1, y1), xdiff, ydiff, city_map, list.new()),
      antinode_part_2_helper(
        #(x2, y2),
        -1 * xdiff,
        -1 * ydiff,
        city_map,
        list.new(),
      ),
    ]
    |> list.flatten
  })
  |> list.flatten
  |> list.filter(fn(coord) { result.is_ok(dict.get(city_map, coord)) })
}

fn antinode_part_2_helper(
  start: Coordinate,
  delta_x: Int,
  delta_y: Int,
  city_map: CityMap,
  accum: List(Coordinate),
) -> List(Coordinate) {
  case dict.get(city_map, start) {
    Ok(_) ->
      antinode_part_2_helper(
        #(pair.first(start) + delta_x, pair.second(start) + delta_y),
        delta_x,
        delta_y,
        city_map,
        list.append(accum, [start]),
      )
    _ -> accum
  }
}

fn antinodes_for_station(
  coords: List(Coordinate),
  city_map: CityMap,
) -> List(Coordinate) {
  coords
  |> list.combination_pairs
  |> list.map(fn(combination_pair) {
    let #(c1, c2) = #(
      pair.first(combination_pair),
      pair.second(combination_pair),
    )
    let #(x1, y1) = #(pair.first(c1), pair.second(c1))
    let #(x2, y2) = #(pair.first(c2), pair.second(c2))
    let xdiff = x1 - x2
    let ydiff = y1 - y2
    [#(x1 + xdiff, y1 + ydiff), #(x2 - xdiff, y2 - ydiff)]
  })
  |> list.flatten
  |> list.filter(fn(coord) { result.is_ok(dict.get(city_map, coord)) })
}

fn create_station_map(city_map: CityMap) -> StationMap {
  dict.filter(city_map, fn(_, value) { value != "." })
  |> dict.to_list
  |> list.fold(dict.new(), fn(accum_dict, station) {
    let #(coord, station) = #(pair.first(station), pair.second(station))
    dict.upsert(accum_dict, station, fn(val) {
      case val {
        option.Some(vals) -> list.append(vals, [coord])
        option.None -> [coord]
      }
    })
  })
}

fn create_city_map(content: String) -> CityMap {
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
