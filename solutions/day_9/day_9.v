module day_9

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	mut next_nums := []i64{}
	for line in input.split('\n').filter(it.len > 0) {
		numbers := parse_numbers(line)!
		next_nums << find_next_in_seq(numbers)!
	}

	return arrays.sum(next_nums)!.str()
}

fn level_2(input string) !string {
	mut prev_nums := []i64{}
	for line in input.split('\n').filter(it.len > 0) {
		numbers := parse_numbers(line)!
		prev_nums << find_prev_in_seq(numbers)!
	}

	return arrays.sum(prev_nums)!.str()
}

fn parse_numbers(input string) ![]i64 {
	mut nums := []i64{}
	for num_str in input.split(' ') {
		nums << num_str.parse_int(10, 64)!
	}

	return nums
}

fn find_next_in_seq(numbers []i64) !i64 {
	mut ends := [numbers[numbers.len - 1]]
	mut step := numbers.clone()
	for {
		derivative := derive(step)
		ends << derivative[derivative.len - 1]
		if is_constant(derivative) {
			break
		}

		unsafe {
			step = derivative
		}
	}

	return arrays.sum(ends)!
}

fn find_prev_in_seq(numbers []i64) !i64 {
	mut starts := [numbers[0]]
	mut step := numbers.clone()
	for {
		derivative := derive(step)
		starts << derivative[0]
		if is_constant(derivative) {
			break
		}

		unsafe {
			step = derivative
		}
	}

	return arrays.reduce(starts.reverse(), fn (a i64, b i64) i64 {
		return b - a
	})!
}

fn derive(numbers []i64) []i64 {
	mut res := []i64{}
	for i in 1 .. numbers.len {
		res << numbers[i] - numbers[i - 1]
	}

	return res
}

fn is_constant(numbers []i64) bool {
	return numbers.all(it == 0)
}
