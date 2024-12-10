import gleam/dict
import gleam/list
import gleam/set
import gleam/string

type Coordinate =
  #(Int, Int)

type Direction {
  Up
  Down
  Left
  Right
}

type Square {
  Empty
  Obstacle
  Guard(direction: Direction)
}

type Maze =
  dict.Dict(Coordinate, Square)

pub fn get_unique_squares(content: String) -> Int {
  let maze = create_maze(content)
  let guard = find_guard(maze)
  case guard {
    // Guard already outside the maze
    Error(_) -> 0
    Ok(g) -> {
      let postprocess_maze = maze |> dict.upsert(g.0, fn(_) { Empty })
      helper(postprocess_maze, g.0, g.1, set.from_list([g.0])) |> set.size
    }
  }
}

fn helper(
  maze: Maze,
  guard_pos: Coordinate,
  guard: Square,
  visited: set.Set(Coordinate),
) -> set.Set(Coordinate) {
  case guard {
    Guard(d) -> {
      let next_square = get_next_square(maze, guard_pos, d)
      case next_square {
        Error(_) -> visited
        Ok(s) -> {
          let s_result = dict.get(maze, s)
          case s_result {
            Error(_) -> panic as "Square must exist"
            Ok(s_type) ->
              case s_type {
                Empty -> helper(maze, s, guard, set.insert(visited, s))
                Obstacle ->
                  helper(maze, guard_pos, Guard(get_next_direction(d)), visited)
                _ -> panic as "Should not be two guards in a maze"
              }
          }
        }
      }
    }
    _ -> panic as "Not a valid guard!"
  }
}

fn get_next_direction(d: Direction) -> Direction {
  case d {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

fn get_next_square(
  maze: Maze,
  start: Coordinate,
  direction: Direction,
) -> Result(Coordinate, Nil) {
  let #(x, y) = #(start.0, start.1)
  let next_square = case direction {
    Up -> #(x - 1, y)
    Down -> #(x + 1, y)
    Left -> #(x, y - 1)
    Right -> #(x, y + 1)
  }
  case dict.has_key(maze, next_square) {
    True -> Ok(next_square)
    _ -> Error(Nil)
  }
}

fn find_guard(maze: Maze) -> Result(#(Coordinate, Square), Nil) {
  maze
  |> dict.filter(fn(_, value) {
    case value {
      Guard(_) -> True
      _ -> False
    }
  })
  |> dict.to_list
  |> list.first
}

fn create_maze(content: String) -> Maze {
  content
  |> string.trim
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    string.to_graphemes(line)
    |> list.index_map(fn(cell, col) { #(#(row, col), get_square(cell)) })
  })
  |> list.flatten
  |> dict.from_list
}

fn get_square(input: String) -> Square {
  case input {
    "." -> Empty
    "#" -> Obstacle
    "v" -> Guard(Down)
    "^" -> Guard(Up)
    ">" -> Guard(Right)
    "<" -> Guard(Left)
    e -> {
      let err = "Invalid square in maze: " <> e
      panic as err
    }
  }
}
