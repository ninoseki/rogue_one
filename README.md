# Rogue one: a rogue DNS detector

[![Build Status](https://travis-ci.org/ninoseki/rogue_one.svg?branch=master)](https://travis-ci.org/ninoseki/rogue_one)
[![Coverage Status](https://coveralls.io/repos/github/ninoseki/rogue_one/badge.svg?branch=master)](https://coveralls.io/github/ninoseki/rogue_one?branch=master)

## Installation

```bash
gem install rogue_one
```

## Usage

```bash
$ rogue_one
Commands:
  rogue_one help [COMMAND]       # Describe available commands or one specific command
  rogue_one report [DNS_SERVER]  # Show a report of a given DNS server

$ rogue_one report 1.1.1.1
{
  "verdict": "rogue one",
  "landing_pages": [

  ]
}

$ rogue_one reprot 1.53.252.215
{
  "verdict": "rogue one",
  "landing_pages": [
    "1.171.170.228",
    "1.171.168.19",
    "61.230.102.66"
  ]
}
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
