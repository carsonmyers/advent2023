module day_1

import arrays
import regex

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 each line is a string of characters - at least one of which is a digit.
// take the first and last digit seen in each line and combine them into a number;
// for the digits [1, 2] the number is 12. Sum the numbers computed from each line
fn level_1(input string) !string {
	nums := input
		.split('\n')
		.filter(fn (line string) bool {
			return line.len > 0
		})
		.map(fn (line string) i64 {
			digits := line
				.bytes()
				.filter(fn (c u8) bool {
					return c.is_digit()
				})
				.map(fn (c u8) i64 {
					return c
						.ascii_str()
						.parse_int(10, 64) or { panic('not a digit ${c}') }
				})

			assert digits.len > 0
			return digits[digits.len - 1] + digits[0] * 10
		})

	return arrays.sum(nums)!.str()
}

// level_2 same as above, but the lines also have digits spelled out in english
// (e.g. "one," "two," etc). The number-words can overlap (e.g. twone) - overlapping
// numbers should still be detected.
fn level_2(input string) !string {
	mut digit_matcher := new_digit_matcher()!
	nums := input
		.split('\n')
		.filter(fn (line string) bool {
			return line.len > 0
		})
		.map(fn [mut digit_matcher] (line string) i64 {
			digits := digit_matcher.match_digit_strings(line)

			assert digits.len > 0
			return digits[digits.len - 1] + digits[0] * 10
		})

	return arrays.sum(nums)!.str()
}

// DigitMatcher is a context struct to carry a mutable regex while matching digit strings
struct DigitMatcher {
pub mut:
	pattern regex.RE
}

fn new_digit_matcher() !DigitMatcher {
	mut pattern := regex.regex_opt(r'((one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)|\d)')!

	DigitMatcher{pattern}
}

// match_digit_strings finds all non-overlapping digits and english words which
// spell out digits in a specified string
fn (mut m &DigitMatcher) match_digit_strings(line string) []i64 {
	// all matching (potentially overlapping) slices of the input
	mut matches := []string{}

	// sub-slice of the input starting just after the beginning of the last match
	mut base := line[..]

	for {
		// get the range of the next matching word or digit
		start, end := m.pattern.find(base)
		if start < 0 {
			break
		}

		// add the digit to the list and shift the base until 1 character after the start
		// of the match - ensuring that we don't re-match the same thing forever or miss
		// overlapping tokens
		matches << base[start..end]
		base = base[start + 1..]
	}

	// translate the matched slices into digits
	return matches.map(match_to_digit)
}

// match_to_digit converts a digit-string ("one," "nine," "7," etc) into an i64
fn match_to_digit(d string) i64 {
	return match d {
		'one' { 1 }
		'two' { 2 }
		'three' { 3 }
		'four' { 4 }
		'five' { 5 }
		'six' { 6 }
		'seven' { 7 }
		'eight' { 8 }
		'nine' { 9 }
		// the regexp matches `\d` (not `\d+`) so all of these matches will be a single digit
		else { d.parse_int(10, 64) or { panic('not a digit ${d}') } }
	}
}
