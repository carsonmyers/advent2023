module solutions

import solutions.day_1
import solutions.day_2

pub fn run(input string, day int, level int) !string {
	assert day > 0 && day <= 25
	assert level == 1 || level == 2

	if day == 1 {
		return day_1.run(input, level)
	} else if day == 2 {
		return day_2.run(input, level)
	} else {
		return error('not implemented')
	}
}
