import gleam/dict
import gleam/list
import gleam/pair
import gleam/result
import gleam/set

import day8_part1

pub fn antinode_count(content: String) -> Int {
  let city_map = day8_part1.create_city_map(content)
  let station_map = day8_part1.create_station_map(city_map)

  dict.values(station_map)
  |> list.filter(fn(coords) { list.length(coords) > 1 })
  |> list.map(fn(station) { antinode_for_station(station, city_map) })
  |> list.fold(set.new(), fn(accum, new_list) {
    new_list |> list.fold(accum, fn(accum, coord) { set.insert(accum, coord) })
  })
  |> set.size
}

fn antinode_for_station(
  coords: List(day8_part1.Coordinate),
  city_map: day8_part1.CityMap,
) -> List(day8_part1.Coordinate) {
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
      helper(#(x1, y1), xdiff, ydiff, city_map, list.new()),
      helper(#(x2, y2), -1 * xdiff, -1 * ydiff, city_map, list.new()),
    ]
    |> list.flatten
  })
  |> list.flatten
  |> list.filter(fn(coord) { result.is_ok(dict.get(city_map, coord)) })
}

fn helper(
  start: day8_part1.Coordinate,
  delta_x: Int,
  delta_y: Int,
  city_map: day8_part1.CityMap,
  accum: List(day8_part1.Coordinate),
) -> List(day8_part1.Coordinate) {
  case dict.get(city_map, start) {
    Ok(_) ->
      helper(
        #(pair.first(start) + delta_x, pair.second(start) + delta_y),
        delta_x,
        delta_y,
        city_map,
        list.append(accum, [start]),
      )
    _ -> accum
  }
}
