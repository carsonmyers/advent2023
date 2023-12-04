module day_4

import math
import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	lines := input.split('\n').filter(fn (line string) bool { return line.len > 0 })
	mut cards := []Card{}
	for line in lines {
		cards << parse_card(line)!
	}

	points := cards.map(fn (card Card) i64 {
		return card.points()
	})

	return arrays.sum(points)!.str()
}

fn level_2(input string) !string {
	lines := input.split('\n').filter(fn (line string) bool { return line.len > 0 })
	mut card_list := []Card{}
	for line in lines {
		card_list << parse_card(line)!
	}

	mut cards := map[i64]Card{}
	mut prize_set := []i64{}
	for card in card_list {
		cards[card.number] = card
		prize_set << card.number
	}

	mut card_count := prize_set.len
	for {
		if prize_set.len == 0 {
			break
		}

		mut next_prizes := []i64{}
		for prize in prize_set {
			card := cards[prize]
			next_prizes << card.prizes()
		}

		card_count += next_prizes.len
		prize_set = next_prizes.clone()
	}

	return card_count.str()
}

struct Card {
	number i64
	given []i64
	winning map[i64]bool
}

fn parse_card(input string) !Card {
	main_parts := input.split(': ')
	if main_parts.len != 2 {
		return error('malformed card: separator `:` did not produce two parts')
	}

	// card name and number might be separated by several spaces
	card_parts := main_parts[0].split(' ').filter(fn (part string) bool { return part.len > 0 })
	if card_parts.len != 2 {
		return error('malformed card: separator ` ` did not produce two parts (card name)')
	}

	number := card_parts[1].parse_int(10, 64)!

	number_parts := main_parts[1].split(' | ')
	if number_parts.len != 2 {
		return error('malformed card: separator `|` did not produce two parts')
	}

	given := parse_numbers(number_parts[0])!
	winning_list := parse_numbers(number_parts[1])!

	mut winning := map[i64]bool{}
	for num in winning_list {
		winning[num] = true
	}

	return Card{number, given, winning}
}

fn parse_numbers(input string) ![]i64 {
	mut numbers := []i64{}
	mut digits := input.bytes().clone()
	for {
		if digits.len == 0 {
			break
		}

		numbers << parse_number(mut digits)!
	}

	return numbers
}

fn parse_number(mut input []u8) !i64 {
	if input.len < 2 {
		return error('malformed card: number input has fewer than two characters left')
	}

	num := input[0..2].bytestr().trim(' ').parse_int(10, 64)!

	if input.len == 2 {
		// only two numbers left in the slice
		input = input[2..].clone()
	} else {
		// there's more data after this number - also skip the space
		input = input[3..].clone()
	}

	return num
}

fn (s &Card) matches() int {
	mut count := 0
	for num in s.given {
		if num in s.winning {
			count += 1
		}
	}

	return count
}

fn (s &Card) points() i64 {
	count := s.matches()
	if count == 0 {
		return 0
	}

	return i64(math.pow(2, count - 1))
}

fn (s &Card) prizes() []i64 {
	count := s.matches()
	mut prizes := []i64{}
	for i in 0..count {
		prizes << s.number + i + 1
	}

	return prizes
}