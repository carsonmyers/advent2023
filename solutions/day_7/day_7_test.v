module day_7

fn test_level_1() {
	input := '32T3K 765
		T55J5 684
		KK677 28
		KTJJT 220
		QQQJA 483'.replace('\t',
		'')

	solution := level_1(input)!
	assert solution == '6440'
}

fn test_level_2() {
	input := '32T3K 765
		T55J5 684
		KK677 28
		KTJJT 220
		QQQJA 483'.replace('\t',
		'')

	solution := level_2(input)!
	assert solution == '5905'
}
