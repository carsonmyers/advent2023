module main

import cli
import os
import time
import solutions

fn main() {
	now := time.now()
	day := if now.month == 12 && now.day <= 25 {
		now.day
	} else {
		1
	}

	mut cmd := cli.Command{
		name: 'aoc23'
		description: 'Advent of Code 2023 solutions by Carson Myers'
		version: '0.1.0'
	}

	cmd.add_flags([
		cli.Flag{
			flag: .int
			name: 'day'
			abbrev: 'd'
			description: 'Select a day of the challenge. Defaults to the current day (if challenge is in progress) or day 1'
		},
		cli.Flag{
			flag: .int
			name: 'part'
			abbrev: 'p'
			description: 'Select a challenge part. Defaults to part 1'
		},
	])
	// cmd.parse(os.args)

	input := os.read_file('./data/day-1-input')!
	solution_1 := solutions.run(input, 1, 2)!
	println('solution part 1: ${solution_1}')
}
