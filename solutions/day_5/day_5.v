module day_5

import time

pub fn run(input string, level int) !string {
	if level == 1 {
		return level_1(input)
	} else {
		return level_2(input)
	}
}

// level_1 is about reading an "almanac" (a set of strange transformations on an input number)
// and finding the nearest location to plant a seed. First it looks up the seed number in the
// seed-to-soil map, then the soil number in the soil-to-fertilizer map, etc., until getting
// the location several steps later.
fn level_1(input string) !string {
	mut b := input.bytes()
	almanac := parse_almanac(mut b, false)!

	mut min_location := i64(-1)
	for seed in almanac.seeds {
		// map a seed number through all the steps until a location is found
		soil := almanac.seeds_soil.map(seed)
		fertilizer := almanac.soil_fertilizer.map(soil)
		water := almanac.fertilizer_water.map(fertilizer)
		light := almanac.water_light.map(water)
		temperature := almanac.light_temperature.map(light)
		humidity := almanac.temperature_humidity.map(temperature)
		location := almanac.humidity_location.map(humidity)

		// record the closest location to plant a seed (lower number = closer)
		if min_location < 0 || location < min_location {
			min_location = location
		}
	}

	return min_location.str()
}

// level_2 changes how the input is to be interpreted; instead of the seeds
// line being a simple list of numbers, it's a list of start-length pairs
// specifying ranges. This dramatically increases the size of the input
fn level_2(input string) !string {
	mut b := input.bytes()
	almanac := parse_almanac(mut b, true)!

	// some metrics for progress printing
	mut last_i := 0
	start_time := time.now()
	mut last_check := time.now()

	len := almanac.seeds.len()
	mut min_location := i64(-1)
	// still just brute force it; I wanted to find all the overlaps between
	// maps to split the input into a set of spans that I could find the nearest
	// minimum for, or use a bunch of evenly space guesses that I optimize to
	// a minimum, but fuck it - it takes awhile but doesn't blow up in memory
	// usage or anything and it doesn't take _that_ long.
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

		// every so often print a status line with elapsed time, percent
		// complete, absolute progress, number tested per second, and current
		// lowest guess.
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

// Almanac is a collection of AlmanacMaps, along with an input of seeds.
struct Almanac {
	seeds                SeedSpec
	seeds_soil           AlmanacMap
	soil_fertilizer      AlmanacMap
	fertilizer_water     AlmanacMap
	water_light          AlmanacMap
	light_temperature    AlmanacMap
	temperature_humidity AlmanacMap
	humidity_location    AlmanacMap
}

// parse_almanac reads an almanac from the input text. It takes up the entire
// input and is the main data structure for the challenge
fn parse_almanac(mut input []u8, use_seed_pairs bool) !Almanac {
	// read the seeds from the top of the almanac. If use_seed_pairs is set,
	// then the seeds are treated as start-length pairs. Otherwise, they are
	// just read as individual numbers.
	first_line := parse_line(mut input)
	line_parts := first_line.bytestr().split(': ')
	if line_parts.len != 2 {
		return error("malformed almanac: separator `:` didn't produce two parts")
	}
	if line_parts[0] != 'seeds' {
		return error('malformed almanac: expected first line to be seeds: ${first_line}')
	}

	seeds := parse_seed_spec(line_parts[1].bytes(), use_seed_pairs)!

	// the maps in the input text are in the same order as the struct layout,
	// so this just progressively reads blocks of text from the input. The input
	// slice is destructively consumed each time an AlmanacMap is parsed, so
	// parse_almanac_map can be called repeatedly with the same input
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

// SeedSpec represents a list of ranges of seed numbers. In level 1, the seed
// line is just a list of individual numbers. A level one seed spec is a list
// of ranges, each with one number in them. Level 2 seed specs are a list of
// start-length pairs that specify a range. A SeedSpec can be used as an
// iterator, which will produce seed numbers through all the ranges.
struct SeedSpec {
	ranges []SeedRange
mut:
	range int
	next  int
}

// parse_seed_spec consumes a line of text to produce a SeedSpec
fn parse_seed_spec(input []u8, use_pairs bool) !SeedSpec {
	seed_data := parse_numbers(input)!

	mut ranges := []SeedRange{}
	if use_pairs {
		// when parsing ranges, there must be an even number of inputs
		if seed_data.len % 2 != 0 {
			return error('cannot use seed number pairs: odd number of seeds')
		}

		// iterate the inputs by pairs
		for i in 0 .. seed_data.len / 2 {
			ranges << SeedRange{
				start: seed_data[i * 2]
				len: seed_data[i * 2 + 1]
			}
		}
	} else {
		// when not parsing pairs, just create a bunch of single-value ranges
		for n in seed_data {
			ranges << SeedRange{
				start: n
				len: 1
			}
		}
	}

	// sort the ranges by start so they are iterated in order.
	// if there is no overlap in the ranges then the iterant should
	// monotonically increase - and we assume there is no overlap.
	ranges.sort(a.start < b.start)

	return SeedSpec{
		ranges: ranges
		range: 0
		next: 0
	}
}

// next implements an iterator interface allowing SeedSpecs to be used in loops
fn (mut r SeedSpec) next() ?i64 {
	// the iterator is exhausted when there are no ranges left
	if r.range >= r.ranges.len {
		return none
	}

	// when one range is exhausted, move on to the next range and recurse so
	// that the above check that there are more ranges to iterate is not missed
	if r.next >= r.ranges[r.range].len {
		r.range += 1
		r.next = 0
		return r.next()
	}

	// produce the next seed
	num := r.ranges[r.range].start + r.next
	r.next += 1
	return num
}

// len reports the total length of the seed spec, as the sum of all its
// constituent ranges
fn (r &SeedSpec) len() i64 {
	mut len := i64(0)
	for range in r.ranges {
		len += range.len
	}

	return len
}

// SeedRange is a single range of seeds, consisting of a start and length
struct SeedRange {
	start i64
	len   i64
}

// AlmanacMap is a map from input numbers to output numbers, consisting of a
// set of ranges that map the input differently
struct AlmanacMap {
	mappings []AlmanacMapping
}

// parse_almanac_map destructively consumes an AlmanacMap from the input text:
//
// seed-to-soil map:
// 50 98 2
// 52 50 48
//
// The header can be checked with src_name and dst_name, which will produce an
// error if it doesn't match. This is to ensure that the maps are present in
// the input in the expected order.
//
// Each line below the header is parsed into an AlmanacMapping
//
// The input slice will be modified to remove the consumed data
fn parse_almanac_map(src_name string, dst_name string, mut input []u8) !AlmanacMap {
	mut matched_name := false
	mut mappings := []AlmanacMapping{}
	for {
		line := parse_line(mut input)

		// maps are broken up by blank lines
		if line.len == 0 {
			// if the name has been matched already then we're done
			if matched_name {
				break
			}

			// if the name has not been mapped yet, then the blank line
			// is before the map - so we still need to proceed to parse the map
			continue
		}

		// the first line of data should be the map name
		if !matched_name {
			// check that the name matches what was expected
			match_name(src_name, dst_name, line.bytestr())!
			matched_name = true
			continue
		}

		// every other data line is a map specification
		mappings << parse_almanac_mapping(line)!
	}

	return AlmanacMap{mappings}
}

// map converts an input number to an output by finding one of the constituent
// AlmanacMappings whose source range contains the input number. If no ranges
// exist that map the number, the source is returned unchanged
fn (m &AlmanacMap) map(src i64) i64 {
	for mapping in m.mappings {
		dst := mapping.map(src) or { continue }

		return dst
	}

	return src
}

// match_name produces an error if a map header specifies a source and target
// other than what is provided. A header is specified like:
//
// soil-to-fertilizer map:
//
// the format `${src_name}-to-${dst_name} map:` is used to match the input line;
// if it doesn't match, an error is produced
fn match_name(src_name string, dst_name string, line string) ! {
	// get the source-to-target part of the header by removing the 'map:' part
	parts := line.split(' ')
	if parts.len != 2 {
		return error('malformed map name: separator ` ` didn\'t produce two parts: ${line}')
	}

	// separate the source from the target by splitting on the '-to-' part
	names := parts[0].split('-to-')
	if names.len != 2 {
		data := parts[0]
		return error('malformed map name: separator `-to-` didn\'t produce two parts: ${data}')
	}

	// the source name is first
	if names[0] != src_name {
		name := names[0]
		return error('unexpected map: expected destination ${dst_name}, found ${name}')
	}

	if names[1] != dst_name {
		name := names[1]
		return error('unexpected map: expected source ${src_name}, found ${name}')
	}
}

// AlmanacMapping is a mapping from a range of input numbers to a range of
// outputs. It is specified like:
//
// 37 52 2
//
// which corresponds to:
//
// destination start: 37
// source start: 52
// range length: 2
//
// and maps input numbers [52, 53] to outputs [37, 38] - effectively subtracting
// (src_start - dst_start) from the input number if it falls within the source
// range.
struct AlmanacMapping {
	dst_start i64
	src_start i64
	len       i64
}

fn parse_almanac_mapping(input []u8) !AlmanacMapping {
	// the line must be 3 numbers
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

// map a source number to a destination number if it falls within the mappings
// source range. Otherwise, returns none
fn (m &AlmanacMapping) map(src i64) ?i64 {
	if src < m.src_start || src >= m.src_start + m.len {
		return none
	}

	offset := src - m.src_start
	return m.dst_start + offset
}

// parse_numbers reads a list of space-separated numbers from an array of
// input bytes
fn parse_numbers(input []u8) ![]i64 {
	mut numbers := []i64{}

	// track the first digit seen of a number to parse it later
	mut number_start := -1

	for i, b in input {
		if b.is_digit() {
			// the first digit of a number was found, so keep track of its
			// position
			if number_start < 0 {
				number_start = i
			}
		} else {
			if number_start >= 0 {
				// the first non-digit byte after a number has been seen.
				numbers << input[number_start..i].bytestr().parse_int(10, 64)!
				number_start = -1
			}
		}
	}

	// edge-case if a number is at the end of the line, and no non-digit
	// bytes triggered the number to be parsed
	if number_start >= 0 {
		numbers << input[number_start..].bytestr().parse_int(10, 64)!
	}

	return numbers
}

// parse_line destructively consumes a line of bytes from the input.
//
// the input slice is mutable, and while the next line will be returned from
// the function, the input passed to the function will be modified to no longer
// contain the line.
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

// find_newline returns the index from the start of the given slice of the next
// newline character, if one exists. Returns none otherwise
fn find_newline(input []u8) ?int {
	for i, b in input {
		if b == `\n` {
			return i
		}
	}

	return none
}
