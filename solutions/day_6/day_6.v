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

// level_1 is a set of toy boat races specified by the time available for the
// race and an all-time record for that race. The race is decided by furthest
// distance rather than fastest time, and they look like:
//
// Time:      7  15   30
// Distance:  9  40  200
//
// where each column is a race. The gimmick is that the boat has to be charge
// for a certain amount of time once the race starts, and during that time it
// doesn't cover any distance. The longer the boat charges, the faster it will
// travel once released (1 mm/ms for every millisecond of charge). Times are
// specified in milliseconds and distances in millimeters.
fn level_1(input string) !string {
	races := parse_races(input, false)!

	// find the product of the number of charge-times that will beat the record
	// for each race
	return arrays.reduce(races.map(it.winning_hold_times_count()), fn (a i64, b i64) i64 {
		return a * b
	})!.str()
}

// level_2 is the same as level 1, but rather than each input column being a
// separate race, it's just one race and the spaces between digits are
// meaningless.
fn level_2(input string) !string {
	races := parse_races(input, true)!
	if races.len != 1 {
		return error('internal error: expected a single race')
	}

	// find the number of different charge-times that will beat the record
	// for the one long race
	return races[0].winning_hold_times_count().str()
}

// Race specifies a boat race by how long it runs for, and what the record
// distance-traveled by a boat is.
struct Race {
	race_time       i64
	record_distance i64
}

fn new_race(race_time i64, record_distance i64) Race {
	return Race{race_time, record_distance}
}

// parse_races constructs a Race for every race specified in the two lines of
// input text. If ignore_spaces is set, then the digits in the input will be
// clumped together into one long number rather than being read as columns.
fn parse_races(input string, ignore_spaces bool) ![]Race {
	// read the time line and distance line for the race data
	lines := input.split('\n').filter(it.len > 0)
	if lines.len != 2 {
		return error('malformed input: more than two lines')
	}

	// parse the data from each line
	times := parse_line(lines[0], ignore_spaces)!
	records := parse_line(lines[1], ignore_spaces)!

	// both lines should specify the same number of data points
	if times.len != records.len {
		return error('malformed input: different numbers of race times and records')
	}

	mut races := []Race{}
	for i in 0 .. times.len {
		races << new_race(times[i], records[i])
	}

	return races
}

// parse_line reads one line of data points (either times or distances) for
// all races in the input text. data points are separated by one or more spaces,
// so this function will return each of the specified numbers - unless
// ignore_spaces is set. When ignoring spaces, only one number will be returned,
fn parse_line(input string, ignore_spaces bool) ![]i64 {
	parts := input.split(':')
	if parts.len != 2 {
		return error('malformed data line: separator `:` did not produce two parts')
	}

	return parse_numbers(parts[1].bytes(), ignore_spaces)
}

// parse_numbers reads a list of space-separated numbers from a byte-array.
// if ignore_spaces is set, only one number will be returned - spaces will be
// skipped and all digits found will be considered to be part of one number
fn parse_numbers(input []u8, ignore_spaces bool) ![]i64 {
	// use a different algorithm to parse a single big number while ignoring
	// non-digit characters if ignore_spaces is set
	if ignore_spaces {
		return [parse_one_long_number(input)!]
	}

	// keep track of the start of each number to parse them at the end
	mut number_start := -1

	mut numbers := []i64{}
	for i, b in input {
		if b.is_digit() {
			// when a digit is found, mark where the number begins
			if number_start < 0 {
				number_start = i
			}
		} else {
			// when no more digits are found in the current number, get a slice
			// of digits from the number's start to this point and parse it
			if number_start >= 0 {
				numbers << input[number_start..i].bytestr().parse_int(10, 64)!
				number_start = -1
			}
		}
	}

	// edge case when the number is at the end of the line, and no non-digit
	// character was read to trigger it being parsed
	if number_start > 0 {
		numbers << input[number_start..].bytestr().parse_int(10, 64)!
	}

	return numbers
}

// parse_one_long_number finds all digits in a byte array, ignoring non-digit
// characters, and combines them together into a single number
fn parse_one_long_number(input []u8) !i64 {
	mut digits := []u8{}
	for b in input {
		if b.is_digit() {
			digits << b
		}
	}

	return digits.bytestr().parse_int(10, 64)!
}

// roots finds the zero-points of a distance equation, which is a parabola,
// using the quadratic formula. Positive values of the equation (distances
// greater than the record) should be between the two zeros.
//
//       y            x           b          x               c
// record_diff = hold_time * (duration - hold_time) - record_distance
// y = x(b - x) - c
// y = bx - x^2 - c
// y = -x^2 + bx - c
// x = -(b +/- sqrt(b^2 - 4c))/2
//
// The inverted parabola is shifted down by the record distance amount, so that
// if the parabola rises above the x-axis, that corresponds to record-beating
// distances
fn (d &Race) roots() (f64, f64) {
	b := f64(d.race_time)
	c := f64(d.record_distance)
	pos := -(-b + math.sqrt(math.pow(b, 2) - 4 * c)) / 2
	neg := -(-b - math.sqrt(math.pow(b, 2) - 4 * c)) / 2

	return pos, neg
}

// winning_hold_times finds the different (integer) lengths of time a boat can
// be charged for that will beat that race's record. The longer the boat is
// charged, the faster it moves - but the less time it has to cover distance.
// A function mapping charge time to distance covered reaches a tipping point,
// where faster movement no longer corresponds to further distances. This
// function is an inverted parabola
fn (d &Race) winning_hold_times() (i64, i64) {
	a_f, b_f := d.roots()
	a := i64(math.floor(a_f + 1))
	b := i64(math.ceil(b_f - 1))

	return a, b
}

// winning_hold_times_count returns the number of integer charge-times that
// can be used to beat a race's record
fn (d &Race) winning_hold_times_count() i64 {
	a, b := d.winning_hold_times()
	return (b + 1) - a
}
