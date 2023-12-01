module main

import cli
import os
import time
import solutions

fn main() {
	now := time.now()
	default_day := if now.month == 12 && now.day <= 25 {
		now.day
	} else {
		1
	}

	mut cmd := cli.Command{
		name: 'advent'
		description: 'Advent of Code 2023 solutions by Carson Myers'
		version: '0.1.0'
	}

	cmd.add_flags([
		cli.Flag{
			flag: .int
			name: 'day'
			abbrev: 'd'
			description: 'Select a day of the challenge. Defaults to the current day (if challenge is in progress) or day 1'
			default_value: [default_day.str()]
		},
	])

	input_cmd := cli.Command{
		name: 'input'
		description: 'Print the challenge input for the specified day'
		execute: fn (cmd cli.Command) ! {
			day := cmd.root().flags.get_int('day')!
			input := load_input(day)!
			print(input)
		}
	}

	solve_cmd := cli.Command{
		name: 'solve'
		description: 'Run the solution for the specified day'
		execute: fn (cmd cli.Command) ! {
			day := cmd.root().flags.get_int('day')!
			input := load_input(day)!

			level_1 := solutions.run(input, day, 1) or { 'no solution: ${err}' }
			level_2 := solutions.run(input, day, 2) or { 'no solution: ${err}' }

			println('level 1: ${level_1}')
			println('level 2: ${level_2}')
		}
	}

	cmd.add_commands([input_cmd, solve_cmd])
	cmd.parse(os.args)
}
