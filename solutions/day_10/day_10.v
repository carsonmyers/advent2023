module day_10

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	pipes := parse_pipes(input)!
	distance_to_furthest_point := (pipes.loop_len + 1) / 2

	return distance_to_furthest_point.str()
}

fn level_2(input string) !string {
	mut pipes := parse_pipes(input)!
	println(pipes.str())
	return pipes.ground_inside.str()
}

struct Pipes {
	start         Pos
	loop_len      int
	ground_inside int
	kind_map      [][]PipeKind
	loop_map      [][]PipeKind
}

fn parse_pipes(input string) !Pipes {
	mut start := Pos{0, 0}
	mut kind_map := [][]PipeKind{}

	for y, line in input.split('\n').filter(it.len > 0) {
		mut kind_line := []PipeKind{}

		for x, b in line.bytes() {
			kind := parse_pipe_kind(b)!
			if kind == .start {
				start.x = x
				start.y = y
			}

			kind_line << kind
		}

		kind_map << kind_line
	}

	mut loop_map := [][]PipeKind{}
	for map_line in kind_map {
		loop_map << []PipeKind{len: map_line.len, cap: map_line.len, init: PipeKind.ground}
	}

	loop_map[start.y][start.x] = .start

	mut current_pos := start
	mut prev_pos := start
	mut steps := 0
	for {
		next_pos := find_next_pipe(current_pos, prev_pos, kind_map)!
		if next_pos.eq(start) {
			break
		}

		loop_map[next_pos.y][next_pos.x] = kind_map[next_pos.y][next_pos.x]

		steps += 1
		prev_pos = current_pos
		current_pos = next_pos
	}

	mut ground_inside := 0
	for y, line in loop_map {
		mut inside := false
		mut entry_corner := PipeKind.se

		for x, cell in line {
			if cell == .vert || cell == .start {
				inside = !inside
				entry_corner = cell
				continue
			}
			if cell == .se || cell == .ne {
				inside = !inside
				entry_corner = cell
			}
			if cell == .sw {
				if entry_corner == .se || entry_corner == .start {
					inside = !inside
				} else {
					entry_corner = .ne
				}
			}
			if cell == .nw {
				if entry_corner == .ne || entry_corner == .start {
					inside = !inside
				} else {
					entry_corner = .se
				}
			}
			if cell == .ground && inside {
				loop_map[y][x] = .inside
				ground_inside += 1
			}
		}
	}

	return Pipes{
		start: start
		loop_len: steps
		ground_inside: ground_inside
		kind_map: kind_map
		loop_map: loop_map
	}
}

fn (p &Pipes) str() string {
	return 'len: ${p.loop_len}, inside: ${p.ground_inside}\norig:\n${p.kind_map.str()}\nloop only:\n${p.loop_map.str()}'
}

fn find_next_pipe(pos Pos, ignore Pos, kind_map [][]PipeKind) !Pos {
	if !pos.is_in_map(kind_map) {
		return error('position is not in map: ${pos.str()}')
	}

	kind := kind_map[pos.y][pos.x]

	mut check := match kind {
		.start { [Direction.up, Direction.right, Direction.down, Direction.left] }
		.vert { [Direction.up, Direction.down] }
		.horiz { [Direction.left, Direction.right] }
		.ne { [Direction.up, Direction.right] }
		.nw { [Direction.up, Direction.left] }
		.sw { [Direction.down, Direction.left] }
		.se { [Direction.down, Direction.right] }
		else { return error('no connections in this position: ${pos.str()}') }
	}

	mut positions := []Pos{}
	for dir in check {
		check_pos := pos.move(dir)
		if check_pos.eq(ignore) {
			continue
		}

		valid_connectors := match dir {
			.up { [PipeKind.vert, PipeKind.sw, PipeKind.se, PipeKind.start] }
			.right { [PipeKind.horiz, PipeKind.nw, PipeKind.sw, PipeKind.start] }
			.down { [PipeKind.vert, PipeKind.nw, PipeKind.ne, PipeKind.start] }
			.left { [PipeKind.horiz, PipeKind.ne, PipeKind.se, PipeKind.start] }
		}

		if check_pos_for(check_pos, valid_connectors, kind_map) {
			positions << check_pos
		}
	}

	if positions.len < 1 {
		return error('not enough connections to position ${pos.str()}: ${positions.len}')
	}

	return positions[0]
}

fn check_pos_for(pos Pos, kinds []PipeKind, kind_map [][]PipeKind) bool {
	if !pos.is_in_map(kind_map) {
		return false
	}

	return kind_map[pos.y][pos.x] in kinds
}

enum PipeKind {
	ground = 0
	vert
	horiz
	ne
	nw
	sw
	se
	start
	inside
}

fn parse_pipe_kind(b u8) !PipeKind {
	return match b {
		`.` { .ground }
		`|` { .vert }
		`-` { .horiz }
		`L` { .ne }
		`J` { .nw }
		`7` { .sw }
		`F` { .se }
		`S` { .start }
		else { error('invalid map character: ${[b].bytestr()}') }
	}
}

fn (k &PipeKind) str() string {
	return match *k {
		.ground { '.' }
		.vert { '│' }
		.horiz { '─' }
		.ne { '└' }
		.nw { '┘' }
		.sw { '┐' }
		.se { '┌' }
		.start { '╳' }
		.inside { '░' }
	}
}

fn (k []PipeKind) str() string {
	return k.map(it.str()).join('')
}

fn (k [][]PipeKind) str() string {
	return k.map(it.str()).join('\n')
}

enum Direction {
	up    = 0
	right
	down
	left
}

struct Pos {
mut:
	x int
	y int
}

fn (p &Pos) move(dir Direction) Pos {
	return match dir {
		.up { p.up() }
		.right { p.right() }
		.down { p.down() }
		.left { p.left() }
	}
}

fn (p &Pos) up() Pos {
	return Pos{p.x, p.y - 1}
}

fn (p &Pos) right() Pos {
	return Pos{p.x + 1, p.y}
}

fn (p &Pos) down() Pos {
	return Pos{p.x, p.y + 1}
}

fn (p &Pos) left() Pos {
	return Pos{p.x - 1, p.y}
}

fn (p &Pos) is_in_map[T](data_map [][]T) bool {
	map_height := data_map.len
	map_width := match map_height {
		0 { 0 }
		else { data_map[0].len }
	}

	return p.x >= 0 && p.y >= 0 && p.x < map_width && p.y < map_height
}

fn (p &Pos) eq(other &Pos) bool {
	return p.x == other.x && p.y == other.y
}

fn (p &Pos) str() string {
	return '(${p.x}, ${p.y})'
}
