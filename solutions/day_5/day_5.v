module day_5

import time

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

fn level_1(input string) !string {
	mut b := input.bytes()
	almanac := parse_almanac(mut b, false)!

	mut min_location := i64(-1)
	for seed in almanac.seeds {
		soil := almanac.seeds_soil.map(seed)
		fertilizer := almanac.soil_fertilizer.map(soil)
		water := almanac.fertilizer_water.map(fertilizer)
		light := almanac.water_light.map(water)
		temperature := almanac.light_temperature.map(light)
		humidity := almanac.temperature_humidity.map(temperature)
		location := almanac.humidity_location.map(humidity)

		if min_location < 0 || location < min_location {
			min_location = location
		}
	}

	return min_location.str()
}

fn level_2(input string) !string {
	mut b := input.bytes()
	almanac := parse_almanac(mut b, true)!

	len := almanac.seeds.len()
	mut last_i := 0
	start_time := time.now()
	mut last_check := time.now()
	mut min_location := i64(-1)
	for i, seed in almanac.seeds {
		soil := almanac.seeds_soil.map(seed)
		fertilizer := almanac.soil_fertilizer.map(soil)
		water := almanac.fertilizer_water.map(fertilizer)
		light := almanac.water_light.map(water)
		temperature := almanac.light_temperature.map(light)
		humidity := almanac.temperature_humidity.map(temperature)
		location := almanac.humidity_location.map(humidity)

		if min_location < 0 || location < min_location {
			min_location = location
		}

		if i % 0x80000 == 0 {
			since_start := time.since(start_time)
			since_last := time.since(last_check)
			percent := 100 * (f64(i) / f64(len))

			per_second := (i - last_i) / since_last.seconds()
			last_check = time.now()
			last_i = i

			println('${since_start:15} > ${percent:.2f}%\t${i}/${len}\t${per_second:.2f}/s\t[lowest so far: ${min_location}]')
		}
	}

	return min_location.str()
}

struct Almanac {
	seeds_soil           AlmanacMap
	soil_fertilizer      AlmanacMap
	fertilizer_water     AlmanacMap
	water_light          AlmanacMap
	light_temperature    AlmanacMap
	temperature_humidity AlmanacMap
	humidity_location    AlmanacMap
mut:
	seeds SeedSpec
}

fn parse_almanac(mut input []u8, use_seed_pairs bool) !Almanac {
	first_line := parse_line(mut input)
	line_parts := first_line.bytestr().split(': ')
	if line_parts.len != 2 {
		return error("malformed almanac: separator `:` didn't produce two parts")
	}
	if line_parts[0] != 'seeds' {
		return error('malformed almanac: expected first line to be seeds: ${first_line}')
	}

	seeds := parse_seed_spec(line_parts[1].bytes(), use_seed_pairs)!

	return Almanac{
		seeds: seeds
		seeds_soil: parse_almanac_map('seed', 'soil', mut input)!
		soil_fertilizer: parse_almanac_map('soil', 'fertilizer', mut input)!
		fertilizer_water: parse_almanac_map('fertilizer', 'water', mut input)!
		water_light: parse_almanac_map('water', 'light', mut input)!
		light_temperature: parse_almanac_map('light', 'temperature', mut input)!
		temperature_humidity: parse_almanac_map('temperature', 'humidity', mut input)!
		humidity_location: parse_almanac_map('humidity', 'location', mut input)!
	}
}

struct SeedSpec {
	ranges []SeedRange
mut:
	range int
	next  int
}

fn parse_seed_spec(input []u8, use_pairs bool) !SeedSpec {
	seed_data := parse_numbers(input)!

	mut ranges := []SeedRange{}
	if use_pairs {
		if seed_data.len % 2 != 0 {
			return error('cannot use seed number pairs: odd number of seeds')
		}

		for i in 0 .. seed_data.len / 2 {
			ranges << SeedRange{
				start: seed_data[i * 2]
				len: seed_data[i * 2 + 1]
			}
		}
	} else {
		for n in seed_data {
			ranges << SeedRange{
				start: n
				len: 1
			}
		}
	}

	ranges.sort(a.start < b.start)

	return SeedSpec{
		ranges: ranges
		range: 0
		next: 0
	}
}

fn (mut r SeedSpec) next() ?i64 {
	if r.range >= r.ranges.len {
		return none
	}

	if r.next >= r.ranges[r.range].len {
		r.range += 1
		r.next = 0
		return r.next()
	}

	num := r.ranges[r.range].start + r.next
	r.next += 1
	return num
}

fn (r &SeedSpec) len() i64 {
	mut len := i64(0)
	for range in r.ranges {
		len += range.len
	}

	return len
}

struct SeedRange {
	start i64
	len   i64
}

struct AlmanacMap {
	mappings []AlmanacMapping
}

fn parse_almanac_map(dst_name string, src_name string, mut input []u8) !AlmanacMap {
	mut matched_name := false
	mut mappings := []AlmanacMapping{}
	for {
		line := parse_line(mut input)
		if line.len == 0 {
			if matched_name {
				break
			}

			continue
		}

		if !matched_name {
			match_name(dst_name, src_name, line.bytestr())!
			matched_name = true
			continue
		}

		mappings << parse_almanac_mapping(line)!
	}

	return AlmanacMap{mappings}
}

fn (m &AlmanacMap) map(src i64) i64 {
	for mapping in m.mappings {
		dst := mapping.map(src) or { continue }

		return dst
	}

	return src
}

fn match_name(dst_name string, src_name string, line string) ! {
	parts := line.split(' ')
	if parts.len != 2 {
		return error('malformed map name: separator ` ` didn\'t produce two parts: ${line}')
	}

	names := parts[0].split('-to-')
	if names.len != 2 {
		data := parts[0]
		return error('malformed map name: separator `-to-` didn\'t produce two parts: ${data}')
	}

	if names[0] != dst_name {
		name := names[0]
		return error('unexpected map: expected destination ${dst_name}, found ${name}')
	}

	if names[1] != src_name {
		name := names[1]
		return error('unexpected map: expected source ${src_name}, found ${name}')
	}
}

struct AlmanacMapping {
	dst_start i64
	src_start i64
	len       i64
}

fn parse_almanac_mapping(input []u8) !AlmanacMapping {
	numbers := parse_numbers(input)!
	if numbers.len != 3 {
		data := input.bytestr()
		return error('malformed almanac map: expected 3 numbers (dst, src, len): ${data}')
	}

	return AlmanacMapping{
		dst_start: numbers[0]
		src_start: numbers[1]
		len: numbers[2]
	}
}

fn (m &AlmanacMapping) map(src i64) ?i64 {
	if src < m.src_start || src >= m.src_start + m.len {
		return none
	}

	offset := src - m.src_start
	return m.dst_start + offset
}

fn parse_numbers(input []u8) ![]i64 {
	mut numbers := []i64{}
	mut number_start := -1
	for i, b in input {
		if b.is_digit() {
			if number_start < 0 {
				number_start = i
			}
		} else {
			if number_start >= 0 {
				numbers << input[number_start..i].bytestr().parse_int(10, 64)!
				number_start = -1
			}
		}
	}

	if number_start >= 0 {
		numbers << input[number_start..].bytestr().parse_int(10, 64)!
	}

	return numbers
}

fn parse_line(mut input []u8) []u8 {
	idx := find_newline(input) or {
		line := input.clone()
		input = []u8{}
		return line
	}

	line := input[0..idx].clone()
	input = input[idx + 1..].clone()
	return line
}

fn find_newline(input []u8) ?int {
	for i, b in input {
		if b == `\n` {
			return i
		}
	}

	return none
}

fn expand_pairs(nums []i64) ![]i64 {
	if nums.len % 2 != 0 {
		return error('cannot use seed number pairs: odd number of seeds')
	}

	mut res := []i64{}
	for i in 0 .. nums.len / 2 {
		start := nums[i * 2]
		len := nums[i * 2 + 1]

		for n in 0 .. len {
			res << n + start
		}
	}

	return res
}
