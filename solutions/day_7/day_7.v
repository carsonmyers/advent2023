module day_7

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	return play_game(input, false)!.str()
}

fn level_2(input string) !string {
	return play_game(input, true)!.str()
}

fn play_game(input string, with_jokers bool) !i64 {
	lines := input.split('\n').filter(it.len > 0)
	mut hands := []Hand{}
	for line in lines {
		hands << parse_hand(line, with_jokers)!
	}

	hands.sort_with_compare(sort_hands)

	mut wins := []i64{}
	for i, hand in hands {
		wins << hand.bid * (i + 1)
	}

	return arrays.sum(wins)!
}

struct Hand {
	cards []Card
	kind  HandKind
	bid   i64
}

fn parse_hand(input string, with_jokers bool) !Hand {
	parts := input.split(' ')
	if parts.len != 2 {
		return error('malformed hand: input should have a card set and a bid')
	}
	if parts[0].len != 5 {
		return error('malformed hand: hand should contain exactly 5 cards')
	}

	mut cards := []Card{}
	for i in 0 .. parts[0].len {
		cards << parse_card(parts[0][i], with_jokers)!
	}

	kind := hand_kind(cards)

	bid := parts[1].parse_int(10, 64)!

	return Hand{cards, kind, bid}
}

fn hand_kind(cards []Card) HandKind {
	mut counts := map[Card]int{}
	mut jokers := 0
	for card in cards {
		if card == .joker {
			jokers += 1
			continue
		}

		if card in counts {
			counts[card] = counts[card] + 1
		} else {
			counts[card] = 1
		}
	}

	mut values := counts.values().sorted()
	if values.len == 0 {
		values = [jokers]
	} else {
		values[values.len - 1] += jokers
	}

	return match values {
		[5] { .five_of_a_kind }
		[1, 4] { .four_of_a_kind }
		[2, 3] { .full_house }
		[1, 1, 3] { .three_of_a_kind }
		[1, 2, 2] { .two_pair }
		[1, 1, 1, 2] { .pair }
		[1, 1, 1, 1, 1] { .high_card }
		else { panic('impossible hand: ${cards.str()}') }
	}
}

fn sort_hands(a &Hand, b &Hand) int {
	if a.kind == b.kind {
		for i in 0 .. a.cards.len {
			if a.cards[i] == b.cards[i] {
				continue
			}

			if int(a.cards[i]) < int(b.cards[i]) {
				return -1
			} else {
				return 1
			}
		}

		return 0
	}

	if int(a.kind) < int(b.kind) {
		return -1
	} else {
		return 1
	}
}

enum Card {
	joker = 0
	two
	three
	four
	five
	six
	seven
	eight
	nine
	ten
	jack
	queen
	king
	ace
}

fn parse_card(input u8, with_jokers bool) !Card {
	if with_jokers && input == `J` {
		return .joker
	}

	return match input {
		`2` { .two }
		`3` { .three }
		`4` { .four }
		`5` { .five }
		`6` { .six }
		`7` { .seven }
		`8` { .eight }
		`9` { .nine }
		`T` { .ten }
		`J` { .jack }
		`Q` { .queen }
		`K` { .king }
		`A` { .ace }
		else { error('invalid card: ${[input].bytestr()}') }
	}
}

fn (c Card) str() string {
	return match c {
		.joker { 'j' }
		.two { '2' }
		.three { '3' }
		.four { '4' }
		.five { '5' }
		.six { '6' }
		.seven { '7' }
		.eight { '8' }
		.nine { '9' }
		.ten { 'T' }
		.jack { 'J' }
		.queen { 'Q' }
		.king { 'K' }
		.ace { 'A' }
	}
}

fn (cs []Card) str() string {
	mut res := ''
	for c in cs {
		res += c.str()
	}

	return res
}

enum HandKind {
	high_card       = 0
	pair
	two_pair
	three_of_a_kind
	full_house
	four_of_a_kind
	five_of_a_kind
}
