module day_11

fn test_level_1() {
	input := '
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....'

	solution := level_1(input)!
	assert solution == '374'
}

fn test_level_2() {
	input := '
...#......
.......#..
#.........
..........
......#...
.#........
.........#
..........
.......#..
#...#.....'

	observation := new_observation(input, 10)
	solution := observation.distance_sum()
	assert solution == 1030
}