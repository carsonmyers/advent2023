module day_6

import math
import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	races := parse_races(input, false)!
	return arrays.reduce(races.map(it.winning_hold_times_count()), fn (a i64, b i64) i64 {
		return a * b
	})!.str()
}

fn level_2(input string) !string {
	races := parse_races(input, true)!
	if races.len != 1 {
		return error('internal error: expected a single race')
	}

	return races[0].winning_hold_times_count().str()
}

// DistanceExn is an equation that describes the total distance traveled for a boat
// given a hold time and race duration. It is used to find record-beating hold-times
// for a given race
//
// distance = hold_time * (duration - hold_time)
// record_diff = distance - record_distance
// winning: record_diff > 0
struct Race {
	race_time       i64
	record_distance i64
}

fn new_race(race_time i64, record_distance i64) !Race {
	return Race{race_time, record_distance}
}

fn parse_races(input string, ignore_spaces bool) ![]Race {
	lines := input.split('\n').filter(it.len > 0)
	if lines.len != 2 {
		return error('malformed input: more than two lines')
	}

	times := parse_line(lines[0], ignore_spaces)!
	records := parse_line(lines[1], ignore_spaces)!

	if times.len != records.len {
		return error('malformed input: different numbers of race times and records')
	}

	mut races := []Race{}
	for i in 0 .. times.len {
		races << new_race(times[i], records[i])!
	}

	return races
}

fn parse_line(input string, ignore_spaces bool) ![]i64 {
	parts := input.split(':')
	if parts.len != 2 {
		return error('malformed data line: separator `:` did not produce two parts')
	}

	return parse_numbers(parts[1].bytes(), ignore_spaces)
}

fn parse_numbers(input []u8, ignore_spaces bool) ![]i64 {
	if ignore_spaces {
		return [parse_one_long_number(input)!]
	}

	mut number_start := -1
	mut numbers := []i64{}
	for i, b in input {
		if b.is_digit() {
			if number_start < 0 {
				number_start = i
			}
		} else {
			if number_start >= 0 {
				numbers << input[number_start..i].bytestr().parse_int(10, 64)!
				number_start = -1
			}
		}
	}

	if number_start > 0 {
		numbers << input[number_start..].bytestr().parse_int(10, 64)!
	}

	return numbers
}

fn parse_one_long_number(input []u8) !i64 {
	mut digits := []u8{}
	for b in input {
		if b.is_digit() {
			digits << b
		}
	}

	return digits.bytestr().parse_int(10, 64)!
}

// roots finds the zero-points of a distance equation, which is a parabola, using the
// quadratic forumla. Positive values of the equation (distances greater than the
// record) should be between the two zeros
//
//       y            x           b          x               c
// record_diff = hold_time * (duration - hold_time) - record_distance
// y = x(b - x) - c
// y = bx - x^2 - c
// y = -x^2 + bx - c
// x = -(b +/- sqrt(b^2 - 4c))/2
fn (d &Race) roots() (f64, f64) {
	b := f64(d.race_time)
	c := f64(d.record_distance)
	pos := -(-b + math.sqrt(math.pow(b, 2) - 4 * c)) / 2
	neg := -(-b - math.sqrt(math.pow(b, 2) - 4 * c)) / 2

	return pos, neg
}

fn (d &Race) winning_hold_times() (i64, i64) {
	a_f, b_f := d.roots()
	a := i64(math.floor(a_f + 1))
	b := i64(math.ceil(b_f - 1))

	return a, b
}

fn (d &Race) winning_hold_times_count() i64 {
	a, b := d.winning_hold_times()
	return (b + 1) - a
}
