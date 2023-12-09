module day_9

fn test_level_1() {
	input := '0 3 6 9 12 15
1 3 6 10 15 21
10 13 16 21 30 45'

	solution := level_1(input)!
	assert solution == '114'
}

fn test_level_2() {
	input := '10 13 16 21 30 45'
	solution := level_2(input)!
	assert solution == '5'
}
