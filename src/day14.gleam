import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/pair
import gleam/result
import gleam/string

type Quadrant {
  Q1
  Q2
  Q3
  Q4
}

type Row =
  Int

type Dx =
  Int

type Dy =
  Int

type Column =
  Int

type Coordinate =
  #(Column, Row)

type Velocity =
  #(Dx, Dy)

type Robot =
  #(Coordinate, Velocity)

pub fn safety_factor(content: String, height: Int, width: Int) -> Int {
  let robots =
    get_robot_positions(content)
    |> list.fold(list.new(), fn(accum, robot) {
      let new_robot =
        list.fold(list.range(0, 99), robot, fn(accum, _) {
          move_robot(accum, width, height)
        })

      list.append(accum, [new_robot])
    })

  let quadrants =
    list.map(robots, fn(x) { get_quadrant(x.0, height, width) })
    |> result.values
    |> list.map(fn(quad) { #(quad, 1) })

  let num_quadrants =
    list.fold(quadrants, dict.new(), fn(accum, quadrant) {
      dict.upsert(accum, quadrant, fn(x) {
        case x {
          option.Some(num) -> num + 1
          _ -> 1
        }
      })
    })

  dict.values(num_quadrants) |> list.fold(1, fn(x, y) { x * y })
}

fn get_quadrant(
  coord: Coordinate,
  height: Int,
  width: Int,
) -> Result(Quadrant, Nil) {
  case int.compare(coord.0, width / 2) {
    order.Eq -> Error(Nil)
    order.Lt ->
      case int.compare(coord.1, height / 2) {
        order.Eq -> Error(Nil)
        order.Lt -> Ok(Q1)
        order.Gt -> Ok(Q3)
      }
    order.Gt ->
      case int.compare(coord.1, height / 2) {
        order.Eq -> Error(Nil)
        order.Lt -> Ok(Q2)
        order.Gt -> Ok(Q4)
      }
  }
}

fn move_robot(robot: Robot, width: Int, height: Int) -> Robot {
  let new_x = robot.0.0 + robot.1.0
  let wrapped_x = case new_x < 0 {
    True -> {
      let adjusted = new_x % width
      case adjusted {
        0 -> 0
        _ -> width + adjusted
      }
    }
    False -> new_x % width
  }

  let new_y = robot.0.1 + robot.1.1
  let wrapped_y = case new_y < 0 {
    True -> {
      let adjusted = new_y % height
      case adjusted {
        0 -> 0
        _ -> height + adjusted
      }
    }
    False -> new_y % height
  }

  let new_coord = #(wrapped_x, wrapped_y)
  #(new_coord, robot.1)
}

fn get_robot_positions(content: String) -> List(Robot) {
  string.trim(content)
  |> string.split("\n")
  |> list.map(fn(line) {
    let parts = string.split(line, " ")
    case parts {
      [pos, vel] -> #(get_coord(pos), get_coord(vel))
      _ -> panic as "Invalid input"
    }
  })
}

fn get_coord(coord_str: String) -> Coordinate {
  let parts = string.split(coord_str, "=")
  case parts {
    [_, rest] ->
      case string.split(rest, ",") {
        [x, y] -> {
          let x_num = int.parse(x)
          let y_num = int.parse(y)
          case x_num, y_num {
            Ok(x_parse), Ok(y_parse) -> #(x_parse, y_parse)
            _, _ -> panic as "Invalid input"
          }
        }
        _ -> panic as "Invalid input"
      }
    _ -> panic as "Invalid input"
  }
}
