import gleam/dict
import gleam/list
import gleam/result
import gleam/set
import gleam/string

type Cell {
  Start
  End
  Empty
  Wall
}

type Direction {
  Up
  Down
  Left
  Right
}

type Row =
  Int

type Column =
  Int

type Coordinate =
  #(Row, Column)

type Maze =
  dict.Dict(Coordinate, Cell)

type Path {
  Path(cells: set.Set(Coordinate), turns: Int)
}

pub fn lowest_score(content: String) -> Int {
  let maze = create_maze(content)
  let start: Coordinate =
    dict.filter(maze, fn(_, cell) {
      case cell {
        Start -> True
        _ -> False
      }
    })
    |> dict.keys
    |> list.first()
    |> result.unwrap(#(0, 0))

  get_all_paths(start, maze)
  |> list.map(score_path)
  |> list.reduce(fn(x, y) {
    case x > y {
      True -> y
      _ -> x
    }
  })
  |> result.unwrap(-1)
}

fn score_path(path: Path) -> Int {
  { set.size(path.cells) - 1 } + { path.turns * 1000 }
}

fn get_all_paths(start: Coordinate, maze: Maze) -> List(Path) {
  // Default facing east
  traverse(start, Right, set.new(), 0, maze)
}

fn traverse(
  coord: Coordinate,
  dir: Direction,
  seen: set.Set(Coordinate),
  turns: Int,
  maze: Maze,
) -> List(Path) {
  case set.contains(seen, coord) {
    True -> []
    False -> {
      let new_seen = set.insert(seen, coord)

      case dict.get(maze, coord) {
        Ok(End) -> [Path(new_seen, turns)]
        Ok(Wall) -> []
        Error(_) -> []
        _ -> {
          let possible_moves = [
            #(Up, #(coord.0 - 1, coord.1)),
            #(Down, #(coord.0 + 1, coord.1)),
            #(Left, #(coord.0, coord.1 - 1)),
            #(Right, #(coord.0, coord.1 + 1)),
          ]

          list.flat_map(possible_moves, fn(move) {
            let #(new_dir, new_coord) = move
            let new_turns = case new_dir {
              d if d == dir -> turns
              _ -> turns + 1
            }

            case dict.get(maze, new_coord) {
              Ok(Wall) -> []
              Error(_) -> []
              _ -> traverse(new_coord, new_dir, new_seen, new_turns, maze)
            }
          })
        }
      }
    }
  }
}

fn create_maze(content: String) -> Maze {
  string.trim(content)
  |> string.split("\n")
  |> list.index_map(fn(line, row) {
    string.to_graphemes(line)
    |> list.index_map(fn(cell, col) {
      let parsed_cell = case cell {
        "#" -> Wall
        "." -> Empty
        "S" -> Start
        "E" -> End
        _ -> panic as "Invalid cell"
      }
      #(#(row, col), parsed_cell)
    })
  })
  |> list.flatten
  |> dict.from_list
}
