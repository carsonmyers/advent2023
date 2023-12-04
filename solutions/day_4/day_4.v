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

// level_1 each line is a scratch-ticket like
// `Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53`, where the first group
// of numbers are given numbers and the second are winning numbers - when
// a given number is present in the winning numbers, the card is worth one
// point; each additional number doubles the number of awarded points. The
// challenge is to sum all points won for all cards.
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

// level_2 revises the rules of the game, where the card number identifies
// the set of all numbers on the card, and every match gives the player the
// prize of...another scratch-ticket. for n matching numbers, the prize is
// the n cards following the winning one (if card 4 matches 2 numbers, the
// prize is new copies of cards 5 and 6). The challenge is to count the
// total number of cards scratched while playing this game over and over with
// all of the original cards and the prize cards.
fn level_2(input string) !string {
	lines := input.split('\n').filter(fn (line string) bool { return line.len > 0 })
	mut card_list := []Card{}
	for line in lines {
		card_list << parse_card(line)!
	}

	// build a map of all the card data, since they'll be re-used when a card
	// is re-awarded as a prize. Also build a set of all card IDs as an input,
	// since the first step will be to play all the original cards
	mut cards := map[i64]Card{}
	mut prize_set := []i64{}
	for card in card_list {
		cards[card.number] = card
		prize_set << card.number
	}

	// track the total number of cards played
	mut card_count := prize_set.len
	for {
		// base-case: no new cards have been awarded
		if prize_set.len == 0 {
			break
		}

		// play all the cards in this step and collect all the prize IDs for
		// the next run through
		mut next_prizes := []i64{}
		for prize in prize_set {
			card := cards[prize]
			next_prizes << card.prizes()
		}

		// record all the newly awarded cards in the card count
		card_count += next_prizes.len

		// use the prizes as the input for the next iteration of the game
		prize_set = next_prizes.clone()
	}

	return card_count.str()
}

// Card is a scratch-ticket game
struct Card {
	number i64
	given []i64
	winning map[i64]bool
}

// parse_card read a scratch-ticket from one line of input
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

	// card ID
	number := card_parts[1].parse_int(10, 64)!

	number_parts := main_parts[1].split(' | ')
	if number_parts.len != 2 {
		return error('malformed card: separator `|` did not produce two parts')
	}

	given := parse_numbers(number_parts[0])!
	winning_list := parse_numbers(number_parts[1])!

	// build a map of winning numbers for faster lookup while checking matches
	mut winning := map[i64]bool{}
	for num in winning_list {
		winning[num] = true
	}

	return Card{number, given, winning}
}

// parse_numbers get a list of numbers from the challenge input. The number
// format looks like `83 86  6 31 17  9 48 53`, where each number is at most
// two digits long, and single digit numbers are padded with an additional
// space.
fn parse_numbers(input string) ![]i64 {
	mut numbers := []i64{}

	// create a mutable set of digits and spaces to be consumed
	mut digits := input.bytes().clone()
	for {
		// base-case: all digits have been consumed
		if digits.len == 0 {
			break
		}

		// `digits` will be partially consumed by this call
		numbers << parse_number(mut digits)!
	}

	return numbers
}

// parse_number reads a single number from a mutable byte-array containing
// game numbers. Two characters are consumed to read the number (the first of
// which can be a space), and then an additional separator space is consumed
// if there is anymore data present.
fn parse_number(mut input []u8) !i64 {
	if input.len < 2 {
		return error('malformed card: number input has fewer than two characters left')
	}

	// read two characters into a string and trim out the space
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

// matches checks the number of matching numbers in the card
fn (s &Card) matches() int {
	mut count := 0
	for num in s.given {
		if num in s.winning {
			count += 1
		}
	}

	return count
}

// points counts the number of points awarded by the card for level 1
fn (s &Card) points() i64 {
	count := s.matches()
	if count == 0 {
		return 0
	}

	// each match doubles the number of points, which is a power series
	return i64(math.pow(2, count - 1))
}

// prizes produces a list of card IDs awarded as prizes by this card
fn (s &Card) prizes() []i64 {
	count := s.matches()
	mut prizes := []i64{}
	for i in 0..count {
		prizes << s.number + i + 1
	}

	return prizes
}