import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleam/string_tree

type Row =
  Int

type Column =
  Int

type Coordinate =
  #(Row, Column)

type Cell {
  Box
  Empty
  Robot
  Wall
}

type Grid =
  dict.Dict(Coordinate, Cell)

type Maze {
  Maze(robot: Coordinate, grid: Grid)
}

type Move {
  Up
  Down
  Left
  Right
}

type MoveParam {
  Search(maze: Maze, move: Move, current: Coordinate, stack: List(Coordinate))
  Unwind(maze: Maze, move: Move, stack: List(Coordinate))
}

pub fn gps_coordinates(maze_input: String, moves_input: String) -> Int {
  let maze = create_maze(maze_input)
  let moves = parse_moves(moves_input)

  let final_maze =
    list.fold(moves, maze, fn(new_maze, move) { make_move(new_maze, move) })

  dict.filter(final_maze.grid, fn(_, value) {
    case value {
      Box -> True
      _ -> False
    }
  })
  |> dict.keys
  |> list.map(calculate_gps)
  |> list.fold(0, fn(x, y) { x + y })
}

fn calculate_gps(coord: Coordinate) {
  { 100 * coord.0 } + coord.1
}

fn make_move(maze: Maze, move: Move) -> Maze {
  let next_coord = get_next_coordinate(maze.robot, move)

  case get_next_cell(maze.robot, maze.grid, move) {
    Wall -> maze
    Empty -> {
      let new_grid = move_to_empty(maze, maze.robot, next_coord, Robot).grid
      Maze(next_coord, new_grid)
    }
    // We need a helper for this
    Box -> move_box(Search(maze, move, next_coord, [maze.robot]))
    Robot -> panic as "Cannot move into the robot"
  }
}

// We are either searching or unwinding.
// In searching, we build up a stack of cells that we need to potentially move.
// We exit the search phase if we find either a Wall or an Empty
// A Wall means we unsuccessfuly wound and return the current maze.
// This means we bypass the Unwinding phase completely.
// If we find Empty, we start the Unwinding phase and move cells in the stack
// one by one until the stack is exhausted.
fn move_box(params: MoveParam) -> Maze {
  case params {
    Search(maze, move, current, stack) -> {
      let next_coord = get_next_coordinate(current, move)
      case get_next_cell(current, maze.grid, move) {
        Robot -> panic as "Should not encounter robot"
        Wall -> maze
        Empty -> move_box(Unwind(maze, move, list.append([current], stack)))
        Box ->
          move_box(Search(maze, move, next_coord, list.append([current], stack)))
      }
    }
    Unwind(maze, move, stack) ->
      case stack {
        [] -> maze
        [top_stack, ..next_stack] -> {
          let next_coord = get_next_coordinate(top_stack, move)
          let next_cell = dict.get(maze.grid, top_stack) |> result.unwrap(Box)
          let next_grid = move_to_empty(maze, top_stack, next_coord, next_cell)
          move_box(Unwind(Maze(next_coord, next_grid.grid), move, next_stack))
        }
      }
  }
}

fn move_to_empty(
  maze: Maze,
  from: Coordinate,
  to: Coordinate,
  to_cell: Cell,
) -> Maze {
  Maze(
    maze.robot,
    dict.upsert(maze.grid, from, fn(get_result) {
      case get_result {
        option.Some(_) -> Empty
        _ -> panic as "Maze must always have cell!"
      }
    })
      |> dict.upsert(to, fn(get_result) {
        case get_result {
          option.Some(_) -> to_cell
          _ -> panic as "Maze must always have cell!"
        }
      }),
  )
}

fn get_next_cell(coord: Coordinate, maze: Grid, move: Move) -> Cell {
  let new_coord = get_next_coordinate(coord, move)
  case dict.get(maze, new_coord) {
    Ok(cell) -> cell
    _ -> panic as "Move must result in valid coordinates"
  }
}

fn get_next_coordinate(coord: Coordinate, move: Move) -> Coordinate {
  let #(row, column) = #(coord.0, coord.1)
  case move {
    Up -> #(row - 1, column)
    Down -> #(row + 1, column)
    Left -> #(row, column - 1)
    Right -> #(row, column + 1)
  }
}

fn create_maze(content: String) -> Maze {
  let grid =
    string.trim(content)
    |> string.split("\n")
    |> list.index_map(fn(line, row) {
      string.to_graphemes(line)
      |> list.index_map(fn(cell, col) {
        let parsed_cell = case cell {
          "#" -> Wall
          "O" -> Box
          "." -> Empty
          "@" -> Robot
          _ -> panic as "Corrupt maze input"
        }

        #(#(row, col), parsed_cell)
      })
    })
    |> list.flatten
    |> dict.from_list

  let robot_coord =
    dict.filter(grid, fn(_, value) {
      case value {
        Robot -> True
        _ -> False
      }
    })
    |> dict.keys()
    |> list.first

  case robot_coord {
    Ok(coord) -> Maze(coord, grid)
    _ -> panic as "No robot found in maze!"
  }
}

fn parse_moves(content: String) -> List(Move) {
  string.trim(content)
  |> string.split("\n")
  |> list.map(fn(line) { string.trim(line) |> string.to_graphemes })
  |> list.flatten
  |> list.map(fn(move) {
    case move {
      "^" -> Up
      "v" -> Down
      "<" -> Left
      ">" -> Right
      _ -> panic as "Corrupt move input"
    }
  })
}

fn print_grid(grid: Grid) -> String {
  let tree = string_tree.new()
  let rows =
    dict.keys(grid)
    |> list.map(pair.first)
    |> set.from_list
    |> set.to_list
    |> list.sort(int.compare)

  list.map(rows, fn(row) {
    let row_cells =
      dict.filter(grid, fn(key, _) { key.0 == row })
      |> dict.to_list
      |> list.sort(fn(first, second) { int.compare(first.0.1, second.0.1) })
      |> list.map(fn(key_val) { key_val.1 })
    list.map(row_cells, print_cell) |> string.join("") |> string.append("\n")
  })
  |> list.fold(tree, fn(accum, row) { string_tree.append(accum, row) })
  |> string_tree.to_string
}

fn print_cell(cell: Cell) -> String {
  case cell {
    Box -> "O"
    Empty -> "."
    Robot -> "@"
    Wall -> "#"
  }
}
