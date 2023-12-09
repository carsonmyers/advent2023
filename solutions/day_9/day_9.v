module day_9

import arrays

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 is to read historical lists of values and predict the next number
// in each sequence. The solution is the sum of all of the next numbers.
fn level_1(input string) !string {
	mut next_nums := []i64{}
	for line in input.split('\n').filter(it.len > 0) {
		numbers := parse_numbers(line)!
		next_nums << find_next_in_seq(numbers)!
	}

	return arrays.sum(next_nums)!.str()
}

// level_2 is similar to the previous challenge, except it is to predict the
// preceding value of each sequence.
fn level_2(input string) !string {
	mut prev_nums := []i64{}
	for line in input.split('\n').filter(it.len > 0) {
		numbers := parse_numbers(line)!
		prev_nums << find_prev_in_seq(numbers)!
	}

	return arrays.sum(prev_nums)!.str()
}

// parse_numbers reads a list of single-space-separated numbers from the
// input. Numbers are allowed to be negative.
fn parse_numbers(input string) ![]i64 {
	mut nums := []i64{}

	// no more than a single space separates each number
	for num_str in input.split(' ') {
		nums << num_str.parse_int(10, 64)!
	}

	return nums
}

// find_next_in_seq predicts the next value in a sequence by calculating each
// sequence's derivative until a constant function is found. That information
// is used to determine how much needs to be added to the sequence to find
// the next step.
//
// for the sequence 0 3 6 9 12 15:
// the difference between each step is found: 3 3 3 3 3
// the process is repeated: 0 0 0 0
//
// once all the values are zeroes, the next number can be calculated by summing
// the rightmost number of each sequence (the input as well as each computed
// sequence).
fn find_next_in_seq(numbers []i64) !i64 {
	// store the last value of each sequence
	mut ends := [numbers[numbers.len - 1]]

	// store the current sequence being derived
	mut step := numbers.clone()

	for {
		// derive the current step and add the last digit
		derivative := derive(step)
		ends << derivative[derivative.len - 1]

		// once the function has been reduced to a constant, we're done
		if is_constant(derivative) {
			break
		}

		// set the derivative to the next step to repeat the process
		unsafe {
			step = derivative
		}
	}

	// the sum of the last digits is the next number in the input sequence
	return arrays.sum(ends)!
}

// find_prev_in_seq predicts the previous value in a sequence by calculating
// each sequence's derivative until a constant function is found. That
// information is used to determine how much needs to be subtracted from the
// sequence to find the previous step.
//
// for the sequence 10 13 16 21 30 45:
// the difference between each step is found: 3 3 5 9 15
// the process is repeated: 0 2 4 6
// and again: 2 2 2
// and again: 0 0
//
// once all the values are zeroes, the previous number can be calculated by
// subtracting the first number of each sequence from each other:
//
// 0 2 0 3 10 => 2 - 0 = 2
// 				 0 - 2 = -2
// 				 3 - -2 = 5
// 				 10 - 5 = 5
//
// so the previous digit is 5
fn find_prev_in_seq(numbers []i64) !i64 {
	// store the beginning number of each sequence
	mut starts := [numbers[0]]

	// store the current sequence being derived
	mut step := numbers.clone()
	for {
		// derive the current step and add the first number
		derivative := derive(step)
		starts << derivative[0]

		// once the function has been reduced to constant, we're done
		if is_constant(derivative) {
			break
		}

		// set the derivative to the next step to continue the process
		unsafe {
			step = derivative
		}
	}

	// subtract pairs of the first numbers from each other to find the
	// preceding value of the input sequence
	return arrays.reduce(starts.reverse(), fn (a i64, b i64) i64 {
		return b - a
	})!
}

// derive an input sequence by calculating the distance between each number
fn derive(numbers []i64) []i64 {
	mut res := []i64{}
	for i in 1 .. numbers.len {
		res << numbers[i] - numbers[i - 1]
	}

	return res
}

// is_constant checks if the sequence is the derivative of a constant function
// (all the numbers are 0)
fn is_constant(numbers []i64) bool {
	return numbers.all(it == 0)
}
