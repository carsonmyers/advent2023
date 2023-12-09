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

// level_1 is a task to read a graph to find the number of steps between a
// starting node and an ending node. Each node has two connections (right and
// left) and the first line is a pattern of directions that must be taken when
// navigating the graph. The starting position is a node named 'AAA' and the
// destination is one named 'ZZZ'
fn level_1(input string) !string {
	lines := input.split('\n').filter(it.len > 0)

	// read the directions pattern from the first line
	mut directions := parse_directions(lines[0])!

	// read all of the nodes into a map to easily look them up as we follow
	// the directions in search of the end node
	mut nodes := map[string]Node{}
	for i in 1 .. lines.len {
		node := parse_node(lines[i])!
		nodes[node.id] = node
	}

	// ensure we read a valid set of data; this doesn't guarantee that the
	// search algorithm terminates but should catch any obvious mistakes
	if nodes.len == 0 {
		return error('no nodes read')
	}
	if 'AAA' !in nodes {
		return error('no start node')
	}
	if 'ZZZ' !in nodes {
		return error('no end node')
	}

	// start at the start node and follow the graph according to the directions
	// until the final node is reached
	mut current := nodes['AAA']
	mut steps := 0
	for {
		// we made it!
		if current.id == 'ZZZ' {
			return steps.str()
		}

		// get the next direction and read the left-or-right link to the next
		// node in the graph. Load that node and begin the next step
		dir := directions.next() or { panic('no next direction') }
		current = nodes[current.get(dir)]!
		steps += 1
	}

	// the above loop can only terminate by returning or panicking but the
	// compiler still requires a return statement here for some reason
	return error('nothing found')
}

// level_2 steps up the challenge by designating all nodes whose name ends in A
// as start nodes, and all that end in Z as end nodes. This time ghosts are
// following the map (??) by following the start nodes to the end nodes
// simultaneously. The task is only complete when all paths have reached an
// end node on at the same time.
fn level_2(input string) !string {
	lines := input.split('\n').filter(it.len > 0)
	mut directions := parse_directions(lines[0])!

	// load all the nodes into a map and keep track of the start nodes
	mut nodes := map[string]Node{}
	mut start_nodes := []string{}
	for i in 1 .. lines.len {
		node := parse_node(lines[i])!
		nodes[node.id] = node

		if node.is_start() {
			start_nodes << node.id
		}
	}

	// sanity check
	if nodes.len == 0 {
		return error('no nodes read')
	}
	if start_nodes.len == 0 {
		return error('no start nodes')
	}

	// start searching from each start node in a separate thread
	res := chan i64{}
	for id in start_nodes {
		go search_for_end(id, nodes, directions, res)
	}

	// collect all the shortest paths from start to end nodes through a
	// channel. Note that while there are probably shorter paths which can
	// be found by deviating from the directions, this just accounts for the
	// path length without having to go past the end node because every
	// path hasn't reached their end node together at the same time.
	mut shortest_paths := []i64{}
	for _ in 0 .. start_nodes.len {
		shortest_paths << <-res
	}

	// find the least common multiple of all the path lengths to determine how
	// many steps it will take for all of them to reach an end node at once
	result := arrays.reduce(shortest_paths, fn (a i64, b i64) i64 {
		gcd := greatest_common_divisor(a, b)
		return (a * b) / gcd
	})!

	return result.str()
}

// greatest_common_divisor is the largest number which can divide both numbers
fn greatest_common_divisor(a i64, b i64) i64 {
	if a == 0 {
		return b
	}

	return greatest_common_divisor(b % a, a)
}

// search_for_end is an algorithm which navigates the input nodes for an end
// node (ending in 'Z') by following the given directions. Once the end node
// is found, the number of steps it took to reach it is reported on the
// res channel.
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

// Directions is an infinitely-repeating iterator of left-and-right instructions
// to be followed while traversing the input map
struct Directions {
	directions []Direction
mut:
	idx int
}

// parse_directions read a list of L and R characters from the input and uses
// them to create a Directions struct
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

// next produces the next instruction for reading the map. If the number of
// instructions from the input have been exhausted, wrap back around to the
// beginning
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

// clone is needed to simplify passing the instructions to a thread
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

// Node is a node in the map, which has a name and two connections (left and
// right) to other nodes by name
struct Node {
	id    string
	left  string
	right string
}

// parse_node reads a node from the input. It is specified like:
//
// AAA = (BBB, CCC)
//
// where AAA is the node name, BBB is the 'left' node's name, and CCC is the
// 'right' node's name.
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
