module main

import net.http
import os

fn load_session() !string {
	return os.read_file('.session')!
}

pub fn fetch_input(day int) !string {
	assert day > 0
	assert day <= 25

	url := 'https://adventofcode.com/2023/day/${day}/input'
	mut req := http.new_request(.get, url, '')
	req.add_cookie(name: 'session', value: load_session()!)
	res := req.do()!

	if res.status_code != 200 {
		status := res.status()
		return error('failed to download input for day ${day}: ${status}')
	}

	return res.body
}

pub fn load_input(day int) !string {
	filename := './data/day-${day}-input'
	if os.is_file(filename) {
		return os.read_file(filename)
	}

	input := fetch_input(day)!
	os.write_file(filename, input) or {
		eprintln('WARN: failed to write challenge input for day ${day} to file: ${err}')
	}

	return input
}
