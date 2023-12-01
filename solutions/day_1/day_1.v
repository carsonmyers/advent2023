module day_1

import arrays
import regex

pub fn run(input string, level int) !string {
	if level == 1 {
		return part_1(input)
	} else {
		return part_2(input)
	}
}

pub fn part_1(input string) !string {
	nums := input.split('\n').filter(fn (line string) bool {
		return line.len > 0
	}).map(fn (line string) i64 {
		digits := line.bytes().filter(fn (c u8) bool {
			return c.is_digit()
		}).map(fn (c u8) i64 {
			return c.ascii_str().parse_int(10, 64) or { panic('not a digit ${c}') }
		})

		assert digits.len > 0
		sum := digits[digits.len - 1] + digits[0] * 10

		return sum
	})

	return arrays.sum(nums)!.str()
}

pub fn part_2(input string) !string {
	mut pattern := regex.regex_opt(r'((one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)|\d)')!

	nums := input.split('\n').filter(fn (line string) bool {
		return line.len > 0
	}).map(fn [mut pattern] (line string) i64 {
		mut matches := []string{}
		mut base := line[..]
		for {
			if base.len == 0 {
				break
			}

			start, end := pattern.find(base)
			if start < 0 {
				break
			}

			matches << base[start..end]
			base = base[start + 1..]
		}

		digits := matches.map(fn (d string) i64 {
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
				else { d.parse_int(10, 64) or { panic('not a digit ${d}') } }
			}
		})

		assert digits.len > 0
		sum := digits[digits.len - 1] + digits[0] * 10

		return sum
	})

	return arrays.sum(nums)!.str()
}
