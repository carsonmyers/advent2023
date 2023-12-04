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

// level_1 each line is a game like `Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green`
// representing a set of samples of coloured blocks pulled out of a bag. The first challenge
// is to find games which are possible given a bag with only 12 red, 13 green, and 14 blue
// blocks and sum their IDs
fn level_1(input string) !string {
	limits := Sample{
		red: 12
		green: 13
		blue: 14
	}

	lines := input.split('\n').filter(fn (line string) bool {
		return line.len > 0
	})

	mut game_ids := []int{}
	for line in lines {
		game := parse_game(line)!

		// check that all samples in the game had fewer blocks then the limit
		possible := game.samples.all(fn [limits] (sample Sample) bool {
			return sample.red <= limits.red && sample.green <= limits.green
				&& sample.blue <= limits.blue
		})

		// only save games which are possible
		if possible {
			game_ids << game.number
		}
	}

	return arrays.sum(game_ids)!.str()
}

// level_2 uses the same game input, but with the challenge to find the smallest number of
// blocks of each colour to make the game possible. The results are combined by computing
// the "power" of this minimal sample (number of blocks of each colour multiplied together)
// and summing the resulting powers.
fn level_2(input string) !string {
	lines := input
		.split('\n')
		.filter(fn (line string) bool {
			return line.len > 0
		})

	mut game_powers := []int{}
	for line in lines {
		game := parse_game(line)!

		// compute the smallest number of blocks of each colour necessary to make the game possible,
		// which will be the largest number in the specified samples seen for each colour
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

// parse_game constructs a Game struct from a line of input text, formatted like:
// `Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green`.
fn parse_game(line string) !Game {
	// first level separates `Game 1` from the list of samples
	parts := line.split(': ')
	if parts.len != 2 {
		return error('invalid game line: multiple `:` tokens found')
	}

	game_part := parts[0]
	sample_part := parts[1]

	// split up `Game 1` to get the game ID
	game_parts := game_part.split(' ')
	if game_parts.len != 2 {
		return error('invalid game line: game name should be like `Game n`')
	}

	number := int(game_parts[1].parse_int(10, 32)!)

	// split up the semicolon-separated samples section and parse them with `parse_sample`
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

// parse_sample constructs a `Sample` struct from part of a game's input text, like:
// `3 blue, 4 red`. Only `red`, `green`, and `blue` colours are supported; if a colour
// appears more than once, the last number seen will be used. If a colour does not
// appear in the sample, it will be counted as 0.
fn parse_sample(input string) !Sample {
	groups := input.split(', ')

	mut red := 0
	mut green := 0
	mut blue := 0
	for group in groups {
		// separate the count from the colour
		group_parts := group.split(' ')

		number := int(group_parts[0].parse_int(10, 32)!)
		color := group_parts[1]

		// assign the count to the appropriate colour
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
