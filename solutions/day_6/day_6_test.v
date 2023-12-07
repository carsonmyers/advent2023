module day_6

fn test_level_1() {
	input := 'Time:      7  15   30
		Distance:  9  40  200'.replace('\t', '')

	solution := level_1(input)!
	assert solution == '288'
}

fn test_level_2() {
	input := 'Time:      7  15   30
		Distance:  9  40  200'.replace('\t', '')

	solution := level_2(input)!
	assert solution == '71503'
}
