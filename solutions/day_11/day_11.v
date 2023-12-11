module day_11

import math

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	observation := new_observation(input, 2)
	return observation.distance_sum().str()
}

fn level_2(input string) !string {
	observation := new_observation(input, 1_000_000)
	return observation.distance_sum().str()
}

struct Observation {
	row_map  map[int]i64
	col_map  map[int]i64
	galaxies []Galaxy
}

fn new_observation(input string, expansion_ratio i64) Observation {
	mut rows_seen := map[int]bool{}
	mut cols_seen := map[int]bool{}

	mut max_row := -1
	mut max_col := -1

	mut galaxies := []Galaxy{}
	for row, line in input.split('\n').filter(it.len > 0) {
		for col, b in line {
			if b == `#` {
				rows_seen[row] = true
				max_row = math.max(max_row, row)

				cols_seen[col] = true
				max_col = math.max(max_col, col)

				galaxies << Galaxy{row, col}
			}
		}
	}

	row_map := mult_gaps(rows_seen, expansion_ratio)
	col_map := mult_gaps(cols_seen, expansion_ratio)

	return Observation{row_map, col_map, galaxies}
}

fn (o &Observation) distance_sum() i64 {
	mut res := i64(0)
	for i, a in o.galaxies {
		for j in i .. o.galaxies.len {
			b := o.galaxies[j]

			if a.eq(b) {
				continue
			}

			res += o.distance(a, b)
		}
	}

	return res
}

fn (o &Observation) distance(a Galaxy, b Galaxy) i64 {
	return math.abs(o.row_map[b.row] - o.row_map[a.row]) +
		math.abs(o.col_map[b.col] - o.col_map[a.col])
}

struct Galaxy {
	row int
	col int
}

fn (g &Galaxy) str() string {
	return '(${g.row}, ${g.col})'
}

fn (g &Galaxy) eq(other &Galaxy) bool {
	return g.row == other.row && g.col == other.col
}

fn mult_gaps(nums map[int]bool, mult i64) map[int]i64 {
	mut res := map[int]i64{}
	for num, _ in nums {
		mut missing := 0
		for i in 0 .. num {
			if !nums[i] {
				missing += 1
			}
		}

		res[num] = (num - missing) + (missing * mult)
	}

	return res
}
