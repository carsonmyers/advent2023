module day_11

import math

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 is to help an elf analyze an astronomical observation, by finding
// the sum of the shortest distances between each galaxy that appears in an
// image while accounting for the expansion of the universe. Each galaxy is
// represented in the image with a '#'. Any empty rows or columns should be
// expanded 2x to account for their actual distance apart.
fn level_1(input string) !string {
	observation := new_observation(input, 2)
	return observation.distance_sum().str()
}

// level_2 is the same but each empty row/column should be expanded by
// a million times.
fn level_2(input string) !string {
	observation := new_observation(input, 1_000_000)
	return observation.distance_sum().str()
}

// Observation encapsulates the data related to an astronomical observation,
// including the coordinates of each galaxy, and a map for the rows/columns
// to account for the expansion. The location that a galaxy appears in the
// image is (row, column), whereas its actual location is space is represented
// by (row_map[row], col_map[col])
struct Observation {
	row_map  map[int]i64
	col_map  map[int]i64
	galaxies []Galaxy
}

// new_observation use an input image and known expansion ratio to construct
// an observation.
fn new_observation(input string, expansion_ratio i64) Observation {
	mut rows_seen := map[int]bool{}
	mut cols_seen := map[int]bool{}

	mut galaxies := []Galaxy{}
	for row, line in input.split('\n').filter(it.len > 0) {
		for col, b in line {
			// add the galaxy's location and mark its row and column as
			// occupied, so that that row and column will not be expanded
			if b == `#` {
				rows_seen[row] = true
				cols_seen[col] = true
				galaxies << Galaxy{row, col}
			}
		}
	}

	// expand the gaps in the rows and columns to create the expansion maps
	row_map := mult_gaps(rows_seen, expansion_ratio)
	col_map := mult_gaps(cols_seen, expansion_ratio)

	return Observation{row_map, col_map, galaxies}
}

// distance_sum collect the real distances of each pair of galaxies in the input
// image and sum them together
fn (o &Observation) distance_sum() i64 {
	mut res := i64(0)
	for i, a in o.galaxies {
		// skip the current galaxy and any galaxies already covered by the
		// previous loop to avoid double-counting the pairs (the pair of
		// galaxies (a, b) and (b, a) are the same and their distance only
		// needs to be measured once).
		for j in i + 1 .. o.galaxies.len {
			b := o.galaxies[j]
			res += o.distance(a, b)
		}
	}

	return res
}

// distance measures the real distance between two galaxies. The challenge
// specifies that this means the number of up, down, left, or right steps
// through the image cells, so it's not necessary to mess around with triangles.
// The shortest distance is just the difference in the vertical and horizontal
// directions so just add up the absolute value of those distances
fn (o &Observation) distance(a Galaxy, b Galaxy) i64 {
	return math.abs(o.row_map[b.row] - o.row_map[a.row]) +
		math.abs(o.col_map[b.col] - o.col_map[a.col])
}

// Galaxy is a point structure that denotes a location in the input image
struct Galaxy {
	row int
	col int
}

fn (g &Galaxy) str() string {
	return '(${g.row}, ${g.col})'
}

// mult_gaps expands the empty gaps in the image to get the galaxies' real
// locations, producing a map to transform their measured locations into their
// real locations. `nums` is a map of which rows or columns have galaxies
// present in them
fn mult_gaps(nums map[int]bool, mult i64) map[int]i64 {
	mut res := map[int]i64{}
	for num, _ in nums {
		// the locations are expanded from the top-left, so for each row or
		// column, just the number of preceding rows or columns that don't
		// contain any data is needed
		mut missing := 0
		for i in 0 .. num {
			if !nums[i] {
				missing += 1
			}
		}

		// any galaxies in row/col `num` will be mapped to a more distant
		// location based on how many preceding rows/cols are empty
		res[num] = num + (missing * mult - 1)
	}

	return res
}
