module day_3

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 each line is a schematic like `617*......`, where dots are blank
// spaces, numbers are part numbers, and other symbols are components. Part
// numbers which are adjacent to components in any direction (including
// diagonally) are associated with that component. The task is to add up all
// numbers which are associated with a component
fn level_1(input string) !string {
	// all the hard work is done!
	schematic := new_schematic(input)!

	return arrays.sum(schematic.part_numbers())!.str()
}

// level_2 specifies that components denoted with a `*` and exactly two part
// numbers are gears, whose ratio is determined by the product of the two part
// numbers. The task is to sum all the gear ratios in the input
fn level_2(input string) !string {
	schematic := new_schematic(input)!

	// gears are `*` and have exactly two part numbers - filter out all
	// components that don't match those specifications
	mut gears := []ComponentParts{}
	for component in schematic.component_parts() {
		if component.component == rune(`*`) && component.parts.len == 2 {
			gears << component
		}
	}

	// compute all the gear ratios in the input
	mut ratios := []int{}
	for gear in gears {
		ratios << arrays.reduce(gear.parts, fn (a int, b int) int {
			return a * b
		})!
	}

	return arrays.sum(ratios)!.str()
}

struct Schematic {
	byte_map [][]u8
mut:
	numbers map[int][]PartNumber
	components []Component
}

// new_schematic scanned from the input text
fn new_schematic(data string) !Schematic {
	lines := data.split('\n').filter(fn (line string) bool {
		return line.len > 0
	})

	mut byte_map := [][]u8{}
	line_width := lines[0].len

	// fill the byte map with the schematic data to make further processing easier
	for i, line in lines {
		if line.len != line_width {
			line_number := i + 1
			aberrant_width := line.len
			return error('inconsistent line width: line ${line_number} (width ${aberrant_width}) does not match the detected document width of ${line_width}')
		}

		byte_map << line.bytes()
	}

	numbers := map[int][]PartNumber{}
	components := []Component{}

	// initialize a schematic with empty part numbers and components
	// containers
	mut s := Schematic{byte_map, numbers, components}

	// use scan_line to find all the second-order metadata (numbers
	// and components)
	for y in 0..s.height() {
		s.scan_line(y)!
	}

	return s
}

// width of the schematic (second dimension of byte_map)
fn (s &Schematic) width() int {
	if s.byte_map.len == 0 {
		return 0
	}

	return s.byte_map[0].len
}

// height of the schematic (first dimension of byte_map)
fn (s &Schematic) height() int {
	return s.byte_map.len
}

// scan_line processes the input data one line at a time, finding part numbers
// and components and saving them to the schematic struct. Only valid part
// numbers (those adjacent to a component) are stored, so other lines of the
// input data are also checked while numbers are being scanned.
fn (mut s Schematic) scan_line(y int) ! {
	mut number_start := -1
	mut component_seen_for_number := false

	mut component_in_last_stripe := false
	for x in 0 .. s.width() {
		// a datum is a vertical stripe of 3 bytes centered on the current position
		datum := s.datum_at(x, y)!

		if datum.byte.is_digit() {
			// track whether this stripe or the previous one contained a component
			// to detect whether the number is adjacent to a component
			if datum.component_in_stripe || component_in_last_stripe {
				component_seen_for_number = true
			}

			// initialize a number span if this is the first digit
			if number_start < 0 {
				number_start = x
			}
		} else {
			// if this is the end of the number and a component has been
			// detected adjacent to it (or one is in the immediately
			// succeeding stripe) then add the part number
			if number_start >= 0 {
				if component_seen_for_number || datum.component_in_stripe {
					s.build_number(y, number_start, x)
				}

				number_start = -1
				component_seen_for_number = false
			}

			// store any detected components as well
			if datum.byte != `.` {
				s.components << Component{
					point: Point{
						x,
						y,
					},
					kind: rune(datum.byte)
				}
			}
		}

		// keep track of the presence of a component in the previous stripe
		// to check for adjacency to the left, top-left, or bottom-left of
		// the part number
		component_in_last_stripe = datum.component_in_stripe
	}

	// edge-case: the part number is on the right edge of the schematic
	if number_start >= 0 && component_seen_for_number {
		s.build_number(y, number_start, s.width())
	}
}

// part_numbers list all part numbers found in the schematic
fn (s &Schematic) part_numbers() []int {
	mut numbers := []int{}
	for _, num_list in s.numbers {
		for number in num_list {
			numbers << number.number
		}
	}

	return numbers
}

// component_parts list all components found in the schematic, along with the
// part numbers that accompany them
fn (s &Schematic) component_parts() []ComponentParts {
	mut component_parts := []ComponentParts{}
	for component in s.components {
		parts := s.parts_for(component.point)
		component_parts << ComponentParts{
			component: component.kind,
			parts: parts.map(fn (part PartNumber) int { return part.number }),
		}
	}

	return component_parts
}

// parts_for finds all the part numbers which are adjacent to a given point.
// the association between components and parts isn't stored in the initial
// scan because the components aren't added to the struct until they're
// picked up in `scan_line` - but their adjacency can be detected before
// then if they appear below a part number.
fn (s &Schematic) parts_for(point Point) []PartNumber {
	mut parts := []PartNumber{}

	// check all the part numbers on the three lines surrounding the point
	mut numbers := []PartNumber{}
	numbers << s.numbers[point.y] or { [] }
	numbers << s.numbers[point.y - 1] or { [] }
	numbers << s.numbers[point.y + 1] or { [] }

	for part in numbers {
		// test eight points (all those adjacent to the given point) against
		// each number, testing if they intersect with the number span
		connected := part.span.contains(x: point.x - 1, y: point.y - 1) ||
			part.span.contains(x: point.x - 1, y: point.y) ||
			part.span.contains(x: point.x - 1, y: point.y + 1) ||
			part.span.contains(x: point.x, y: point.y - 1) ||
			part.span.contains(x: point.x, y: point.y + 1) ||
			part.span.contains(x: point.x + 1, y: point.y - 1) ||
			part.span.contains(x: point.x + 1, y: point.y) ||
			part.span.contains(x: point.x + 1, y: point.y + 1)

		if connected {
			parts << part
		}
	}

	return parts
}

// build_number reads a part number from one line of byte_map and adds the
// number and its span to the struct
fn (mut s Schematic) build_number(y int, start int, end int) {
	// slice of bytes that contains the digits of the part number
	digits := s.byte_map[y][start..end]

	mut number := 0
	for digit in digits {
		// just use the byte value of each digit and multiply it into the
		// number, rather than converting the digits to a string and parsing.
		// There should not be any non-digit characters contained in `digits`
		number = number * 10 + (digit - u8(`0`))
	}

	// store the part numbers by line of input to make testing them for
	// adjacency later more efficient.
	mut numbers := s.numbers[y] or { [] }

	numbers << PartNumber{
		span: Span{
			y,
			start,
			end,
		},
		number: number,
	}

	s.numbers[y] = numbers
}

// datum_at gets a datum from a specified point in the input.
fn (s &Schematic) datum_at(x int, y int) !Datum {
	datum := s.data_at(x, y)!

	mut component_in_stripe := false

	// check if there's a component within a three-character high 'stripe'
	// centered on the given point
	component_in_stripe = component_in_stripe || s.component_at(x, y - 1) or { false }
	component_in_stripe = component_in_stripe || s.component_at(x, y) or { false }
	component_in_stripe = component_in_stripe || s.component_at(x, y + 1) or { false }

	return Datum{x, y, datum, component_in_stripe}
}

// data_at reads the byte stored at a given point in the input
fn (s &Schematic) data_at(x int, y int) !u8 {
	if y >= s.byte_map.len || y < 0 {
		height := s.byte_map.len
		return error('${y} is outside the document\'s height of ${height}')
	}

	line := s.byte_map[y]
	if x >= line.len || x < 0 {
		width := line.len
		return error('${x} is outside the document\'s width of ${width}')
	}

	return line[x]
}

// component_at tests whether a component exists at a given point in the input
fn (s &Schematic) component_at(x int, y int) !bool {
	datum := s.data_at(x, y)!

	return datum != `.` && !datum.is_digit()
}

// Datum represents a piece of data and some associated metadata at a specific
// point in the input; the position of the datum, the byte value that is
// stored there, and whether a 3-character high stripe centered on that point
// contains a component.
struct Datum {
pub:
	x                   int
	y                   int
	byte               u8
	component_in_stripe bool
}

// ComponentParts represents a component and the part numbers associated with
// it - leaving out the spans and points where that information was collected
struct ComponentParts {
	component rune
	parts []int
}

// PartNumber is a number that was found in the input, along with the span
// where it was found. All PartNumber's are adjacent to a component
struct PartNumber {
	span Span
	number int
}

// Component represents a non-number, non-`.` character that was found in the
// input, along with the point in the data where it was collected
struct Component {
	point Point
	kind rune
}

// Span is a set of bytes on one line of input (`y`) denoted between two
// x values [`start`, `end`)
struct Span {
	y int
	start int
	end int
}

// contains tests whether a given point falls within the span
fn (s &Span) contains(point Point) bool {
	if point.y != s.y {
		return false
	}

	return s.start <= point.x && point.x < s.end
}

// Point represents a single byte in the input data
struct Point {
	x int
	y int
}