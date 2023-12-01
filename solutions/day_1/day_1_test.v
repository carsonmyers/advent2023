module day_1

fn test_level_1() {
	input := '1abc2
		pqr3stu8vwx
		a1b2c3d4e5f
		treb7uchet'.replace('\t', '')

	solution := level_1(input)!
	assert solution == '142'
}

fn test_level_2() {
	input := 'two1nine
		eightwothree
		abcone2threexyz
		xtwone3four
		4nineeightseven2
		zoneight234
		7pqrstsixteen'.replace('\t',
		'')

	solution := level_2(input)!
	assert solution == '281'
}
