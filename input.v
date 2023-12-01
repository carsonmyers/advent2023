module main

import net.http
import os

fn load_session() !string {
	return os.read_file(".session")!
}

pub fn fetch_input(day int) !string {
	assert day > 0
	assert day <= 25

	mut req := http.new_request(.get, 'https://adventofcode.com/2023/day/${day}/input', '');
	req.add_cookie(name: 'session', value: load_session()!)

	return ''
}