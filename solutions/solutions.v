module solutions

import solutions.day_1
import solutions.day_2
import solutions.day_3
import solutions.day_4
import solutions.day_5
import solutions.day_6

pub fn run(input string, day int, level int) !string {
	assert day > 0 && day <= 25
	assert level == 1 || level == 2

	if day == 1 {
		return day_1.run(input, level)
	} else if day == 2 {
		return day_2.run(input, level)
	} else if day == 3 {
		return day_3.run(input, level)
	} else if day == 4 {
		return day_4.run(input, level)
	} else if day == 5 {
		return day_5.run(input, level)
	} else if day == 6 {
		return day_6.run(input, level)
	} else {
		return error('not implemented')
	}
}
