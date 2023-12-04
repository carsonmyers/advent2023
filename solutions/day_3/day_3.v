module day_3

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	schematic := new_schematic(input)!

	return arrays.sum(schematic.part_numbers())!.str()
}

fn level_2(input string) !string {
	schematic := new_schematic(input)!

	mut gears := []ComponentParts{}
	for component in schematic.component_parts() {
		if component.component == rune(`*`) && component.parts.len == 2 {
			gears << component
		}
	}

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

fn new_schematic(data string) !Schematic {
	lines := data.split('\n').filter(fn (line string) bool {
		return line.len > 0
	})

	mut byte_map := [][]u8{}
	line_width := lines[0].len

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

	mut s := Schematic{byte_map, numbers, components}

	for y in 0..s.height() {
		s.scan_line(y)!
	}

	return s
}

fn (s &Schematic) width() int {
	if s.byte_map.len == 0 {
		return 0
	}

	return s.byte_map[0].len
}

fn (s &Schematic) height() int {
	return s.byte_map.len
}

fn (mut s Schematic) scan_line(y int) ! {
	mut number_start := -1
	mut component_seen_for_number := false

	mut component_in_last_stripe := false
	for x in 0 .. s.width() {
		datum := s.datum_at(x, y)!

		if datum.byte.is_digit() {
			if datum.component_in_stripe || component_in_last_stripe {
				component_seen_for_number = true
			}

			if number_start < 0 {
				number_start = x
			}
		} else {
			if number_start >= 0 {
				if component_seen_for_number || datum.component_in_stripe {
					s.build_number(y, number_start, x)
				}

				number_start = -1
				component_seen_for_number = false
			}

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

		component_in_last_stripe = datum.component_in_stripe
	}

	if number_start >= 0 && component_seen_for_number {
		s.build_number(y, number_start, s.width())
	}
}

fn (s &Schematic) part_numbers() []int {
	mut numbers := []int{}
	for _, num_list in s.numbers {
		for number in num_list {
			numbers << number.number
		}
	}

	return numbers
}

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

fn (s &Schematic) parts_for(point Point) []PartNumber {
	mut parts := []PartNumber{}

	mut numbers := []PartNumber{}
	numbers << s.numbers[point.y] or { [] }
	numbers << s.numbers[point.y - 1] or { [] }
	numbers << s.numbers[point.y + 1] or { [] }

	for part in numbers {
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

fn (mut s Schematic) build_number(y int, start int, end int) {
	digits := s.byte_map[y][start..end]

	mut number := 0
	for digit in digits {
		number = number * 10 + (digit - u8(`0`))
	}

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

fn (s &Schematic) datum_at(x int, y int) !Datum {
	datum := s.data_at(x, y)!

	mut component_in_stripe := false

	component_in_stripe = component_in_stripe || s.component_at(x, y - 1) or { false }
	component_in_stripe = component_in_stripe || s.component_at(x, y) or { false }
	component_in_stripe = component_in_stripe || s.component_at(x, y + 1) or { false }

	return Datum{x, y, datum, component_in_stripe}
}

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

fn (s &Schematic) component_at(x int, y int) !bool {
	datum := s.data_at(x, y)!

	return datum != `.` && !datum.is_digit()
}

struct Datum {
pub:
	x                   int
	y                   int
	byte               u8
	component_in_stripe bool
}

struct ComponentParts {
	component rune
	parts []int
}

struct PartNumber {
	span Span
	number int
}

struct Component {
	point Point
	kind rune
}

struct Span {
	y int
	start int
	end int
}

fn (s &Span) contains(point Point) bool {
	if point.y != s.y {
		return false
	}

	return s.start <= point.x && point.x < s.end
}

struct Point {
	x int
	y int
}