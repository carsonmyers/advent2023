module day_8

import pcre
import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	lines := input.split('\n').filter(it.len > 0)
	mut directions := parse_directions(lines[0])!

	mut nodes := map[string]Node{}
	for i in 1 .. lines.len {
		node := parse_node(lines[i])!
		nodes[node.id] = node
	}

	if nodes.len == 0 {
		return error('no nodes read')
	}

	if 'AAA' !in nodes {
		return error('no start node')
	}
	if 'ZZZ' !in nodes {
		return error('no end node')
	}

	mut current := nodes['AAA']
	mut steps := 0
	for {
		if current.id == 'ZZZ' {
			return steps.str()
		}

		dir := directions.next() or { panic('no next direction') }
		current = nodes[current.get(dir)]!
		steps += 1
	}

	return error('nothing found')
}

fn level_2(input string) !string {
	lines := input.split('\n').filter(it.len > 0)
	mut directions := parse_directions(lines[0])!

	mut nodes := map[string]Node{}
	mut start_nodes := []string{}
	for i in 1 .. lines.len {
		node := parse_node(lines[i])!
		nodes[node.id] = node

		if node.is_start() {
			start_nodes << node.id
		}
	}

	if nodes.len == 0 {
		return error('no nodes read')
	}
	if start_nodes.len == 0 {
		return error('no start nodes')
	}

	res := chan i64{}
	for id in start_nodes {
		go search_for_end(id, nodes, directions, res)
	}

	mut shortest_paths := []i64{}
	for _ in 0 .. start_nodes.len {
		shortest_paths << <-res
	}

	result := arrays.reduce(shortest_paths, fn (a i64, b i64) i64 {
		gcd := greatest_common_divisor(a, b)
		return (a * b) / gcd
	})!

	return result.str()
}

fn greatest_common_divisor(a i64, b i64) i64 {
	if a == 0 {
		return b
	}

	return greatest_common_divisor(b % a, a)
}

fn search_for_end(start string, nodes map[string]Node, directions &Directions, res chan i64) {
	mut steps := i64(0)
	mut current := nodes[start]
	mut dir := directions.clone()
	for {
		if current.is_end() {
			res <- steps
			return
		}

		next_dir := dir.next() or { panic('no direction') }
		current = nodes[current.get(next_dir)]
		steps += 1
	}
}

struct Directions {
	directions []Direction
mut:
	idx int
}

fn parse_directions(input string) !Directions {
	mut directions := []Direction{}
	for c in input {
		directions << match c {
			`L` { .left }
			`R` { .right }
			else { return error('invalid direction: ${c}') }
		}
	}

	return Directions{
		directions: directions
		idx: 0
	}
}

fn (mut d Directions) next() ?Direction {
	if d.directions.len == 0 {
		return none
	}

	if d.idx == d.directions.len {
		d.idx = 0
	}

	res := d.directions[d.idx]
	d.idx += 1
	return res
}

fn (d &Directions) clone() Directions {
	return Directions{
		directions: d.directions.clone()
		idx: 0
	}
}

enum Direction {
	left  = 0
	right
}

struct Node {
	id    string
	left  string
	right string
}

fn parse_node(input string) !Node {
	pattern := pcre.new_regex(r'^(\w+) = \((\w+), (\w+)\)$', 0)!
	m := pattern.match_str(input, 0, 0) or { return error('malformed node: "${input}"') }

	id := m.get(1) or { panic('no id match') }
	left := m.get(2) or { panic('no left match') }
	right := m.get(3) or { panic('no right match') }

	return Node{id, left, right}
}

fn (n &Node) get(direction Direction) string {
	return match direction {
		.left { n.left }
		.right { n.right }
	}
}

fn (n &Node) is_start() bool {
	return n.id.ends_with('A')
}

fn (n &Node) is_end() bool {
	return n.id.ends_with('Z')
}
