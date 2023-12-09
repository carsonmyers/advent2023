module day_7

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 is a card game similar to poker, where hands can be compared and
// ranked. In a game, each hand has a bid associated with it, and the winnings
// for that hand correspond to where it falls in the ranked list. In a game
// with 100 hands, and a winning hand with a bid of 50, the prize is the bid
// (50) multiplied by its inverse-rank (100) for a prize of 5000. The task is
// to rank a given set of hands and bids, calculate the winnings for each hand,
// and sum the total winnings.
fn level_1(input string) !string {
	return play_game(input, false)!.str()
}

// level_2 modifies the game by replacing the jack card with a joker. Jokers
// can stand in for any other card in order to make a stronger hand - but it is
// also the weakest card when comparing hands of the same kind. The task is to
// recalculate the total winnings based on these new rules
fn level_2(input string) !string {
	return play_game(input, true)!.str()
}

// play_game runs the challenge by ranking all the given hands and calculating
// the total winnings for the game. Whether the joker rule is in effect is
// controlled with `with_jokers`
fn play_game(input string, with_jokers bool) !i64 {
	lines := input.split('\n').filter(it.len > 0)
	mut hands := []Hand{}
	for line in lines {
		hands << parse_hand(line, with_jokers)!
	}

	// sort the input hands according to the game rules
	hands.sort_with_compare(sort_hands)

	println('\nnew game (jokers: ${with_jokers})')
	mut wins := []i64{}
	for i, hand in hands {
		// calculate the hand's winnings according to its rank
		win := hand.bid * (i + 1)
		println('${hand.cards.str()}\t${hand.kind}\tbid: ${hand.bid:03}\twin: ${win}')
		wins << win
	}

	return arrays.sum(wins)!
}

// Hand is a hand of cards in the game along with its bid and a (calculated)
// hand kind. The input looks like `KK677 28`, which corresponds to a hand with
// two kings, a six, and two sevens, along with a bid of 28. This hand's kind
// is calculated to be a two-pair.
struct Hand {
	cards []Card
	kind  HandKind
	bid   i64
}

// parse_hand reads a hand and bid from the input text
fn parse_hand(input string, with_jokers bool) !Hand {
	// the hand and bid are separated by a space
	parts := input.split(' ')
	if parts.len != 2 {
		return error('malformed hand: input should have a card set and a bid')
	}

	// the hand must be exactly 5 bytes long
	if parts[0].len != 5 {
		return error('malformed hand: hand should contain exactly 5 cards')
	}

	// read each byte of the hand into a card
	mut cards := []Card{}
	for i in 0 .. parts[0].len {
		cards << parse_card(parts[0][i], with_jokers)!
	}

	// figure out what kind of hand it is
	kind := hand_kind(cards)

	// parse the bid to a number
	bid := parts[1].parse_int(10, 64)!

	return Hand{cards, kind, bid}
}

// hand_kind calculates the type of a hand based on its cards
fn hand_kind(cards []Card) HandKind {
	mut counts := map[Card]int{}
	mut jokers := 0
	for card in cards {
		// jokers will be saved for later to increase the strength of the hand
		if card == .joker {
			jokers += 1
			continue
		}

		// count how many times each kind of card appears in the hand
		if card in counts {
			counts[card] = counts[card] + 1
		} else {
			counts[card] = 1
		}
	}

	// to determine a hand's kind, all we need are the total counts, not the
	// actual card faces. When the values are sorted, this forms a "pattern"
	// for the hand which identifies its kind
	mut values := counts.values().sorted()

	// jokers can be used to improve the had by counting them as whatever card
	// there is already the most of; this is done by adding the joker count to
	// the last item in the values array.
	if values.len == 0 {
		// if all the cards are jokers then no cards will have been counted and
		// the values array will be empty
		values = [jokers]
	} else {
		// increase the highest count by the number of jokers
		values[values.len - 1] += jokers
	}

	// match the hand's count pattern to a hand kind after accounting for
	// any jokers that may have been present; for exactly five cards, there
	// are exactly seven ways to form this pattern and each corresponds to
	// a different hand kind
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

// sort_hands sorts hands with weaker hands coming before stronger hands, so
// that the strongest hand has the highest rank. Hands are ordered first by
// kind (with high-card being the weakest, and five-of-a-kind being strongest)
// and hands of the same kind are ordered by the specific card faces.
//
// When comparing face values, cards are read from left-to-right and compared
// in order until a difference is found, at which point whichever hand has a
// lower card in that position will be sorted earlier. So KJ444 will sort
// higher than KJ3KK, because they're both three-of-a-kind and the first
// card that differs in each hand is 4 and 3 respectively.
fn sort_hands(a &Hand, b &Hand) int {
	// for equal hands, sort them by individual card face
	if a.kind == b.kind {
		for i in 0 .. a.cards.len {
			// skip cards until a difference is found
			if a.cards[i] == b.cards[i] {
				continue
			}

			// sort the hand based on the difference in the card faces at
			// whatever position happens to have the first difference
			if int(a.cards[i]) < int(b.cards[i]) {
				return -1
			} else {
				return 1
			}
		}

		// both hands have identical cards
		return 0
	}

	// sort the hands by kind
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

// parse_card reads a card from an input byte. If the jokers rule is in
// effect, then 'J' corresponds to a joker instead of a jack.
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

// str prints a card as a string, making debug prints of hands easier
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

// str prints an array of cards as a string, making debug prints easier
fn (cs []Card) str() string {
	mut res := ''
	for c in cs {
		res += c.str()
	}

	return res
}

// HandKind an ordered enum of different types of hands, with high_card being
// the weakest and five-of-a-kind being the strongest.
enum HandKind {
	high_card       = 0
	pair
	two_pair
	three_of_a_kind
	full_house
	four_of_a_kind
	five_of_a_kind
}
