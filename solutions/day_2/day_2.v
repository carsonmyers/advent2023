module day_2

import arrays
import math

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	limits := Sample{
		red: 12
		green: 13
		blue: 14
	}

	lines := input.split('\n').filter(fn (line string) bool {
		return line.len > 0
	})

	mut games := []Game{}
	for line in lines {
		game := parse_game(line)!
		possible := game.samples.all(fn [limits] (sample Sample) bool {
			return sample.red <= limits.red && sample.green <= limits.green
				&& sample.blue <= limits.blue
		})

		if possible {
			games << game
		}
	}

	return arrays.sum(games.map(fn (game Game) int {
		return game.number
	}))!.str()
}

fn level_2(input string) !string {
	lines := input
		.split('\n')
		.filter(fn (line string) bool {
			return line.len > 0
		})

	mut games := []Game{}
	for line in lines {
		games << parse_game(line)!
	}

	mut game_powers := []int{}
	for game in games {
		minimal_sample := arrays.reduce(game.samples, fn (acc Sample, sample Sample) Sample {
			return Sample{
				red: math.max(acc.red, sample.red)
				green: math.max(acc.green, sample.green)
				blue: math.max(acc.blue, sample.blue)
			}
		})!

		game_powers << minimal_sample.power()
	}

	return arrays.sum(game_powers)!.str()
}

struct Game {
pub:
	number  int
	samples []Sample
}

fn parse_game(line string) !Game {
	parts := line.split(': ')
	if parts.len != 2 {
		return error('invalid game line: multiple `:` tokens found')
	}

	game_part := parts[0]
	sample_part := parts[1]

	game_parts := game_part.split(' ')
	if game_parts.len != 2 {
		return error('invalid game line: game name should be like `Game n`')
	}

	number := int(game_parts[1].parse_int(10, 32)!)

	mut samples := []Sample{}
	for sample in sample_part.split('; ') {
		samples << parse_sample(sample)!
	}

	return Game{number, samples}
}

struct Sample {
pub:
	red   int
	green int
	blue  int
}

fn parse_sample(input string) !Sample {
	groups := input.split(', ')

	mut red := 0
	mut green := 0
	mut blue := 0
	for group in groups {
		group_parts := group.split(' ')
		number := int(group_parts[0].parse_int(10, 32)!)
		color := group_parts[1]
		match color {
			'red' { red = number }
			'green' { green = number }
			'blue' { blue = number }
			else { return error('invalid colour ${color}') }
		}
	}

	return Sample{red, green, blue}
}

fn (s &Sample) power() int {
	return s.red * s.green * s.blue
}
