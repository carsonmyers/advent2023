module day_8

fn test_level_1() {
	input := 'RL

		AAA = (BBB, CCC)
		BBB = (DDD, EEE)
		CCC = (ZZZ, GGG)
		DDD = (DDD, DDD)
		EEE = (EEE, EEE)
		GGG = (GGG, GGG)
		ZZZ = (ZZZ, ZZZ)'.replace('\t',
		'')

	solution := level_1(input)!
	assert solution == '2'

	input_2 := 'LLR

		AAA = (BBB, BBB)
		BBB = (AAA, ZZZ)
		ZZZ = (ZZZ, ZZZ)'.replace('\t',
		'')

	solution_2 := level_1(input_2)!
	assert solution_2 == '6'
}

fn test_level_2() {
	input := 'LR

		11A = (11B, XXX)
		11B = (XXX, 11Z)
		11Z = (11B, XXX)
		22A = (22B, XXX)
		22B = (22C, 22C)
		22C = (22Z, 22Z)
		22Z = (22B, 22B)
		XXX = (XXX, XXX)'.replace('\t',
		'')

	solution := level_2(input)!
	assert solution == '6'
}
