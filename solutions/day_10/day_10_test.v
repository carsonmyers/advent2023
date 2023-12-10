module day_10

fn test_level_1() {
	input := '7-F7-
.FJ|7
SJLL7
|F--J
LJ.LJ'

	solution := level_1(input)!
	assert solution == '8'
}

fn test_level_2() {
	input := '
..........
.S------7.
.|F----7|.
.||....||.
.||....||.
.|L-7F-J|.
.|..||..|.
.L--JL--J.
..........'

	solution := level_2(input)!
	assert solution == '4'
}

fn test_level_2_2() {
	input := '
FF7FSF7F7F7F7F7F---7
L|LJ||||||||||||F--J
FL-7LJLJ||||||LJL-77
F--JF--7||LJLJ7F7FJ-
L---JF-JLJ.||-FJLJJ7
|F|F-JF---7F7-L7L|7|
|FFJF7L7F-JF7|JL---7
7-L-JL7||F7|L7F-7F7|
L.L7LFJ|||||FJL7||LJ
L7JLJL-JLJLJL--JLJ.L'

	solution := level_2(input)!
	assert solution == '10'
}
