# Rogue one: a rogue DNS detector

[![Gem Version](https://badge.fury.io/rb/rogue_one.svg)](https://badge.fury.io/rb/rogue_one)
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
  "verdict": "benign one",
  "landing_pages": [

  ]
}

$ rogue_one report 1.53.252.215
{
  "verdict": "rogue one",
  "landing_pages": [
    "1.171.168.19",
    "1.171.170.228",
    "61.230.102.66"
  ]
}
```

| Key           | Desc.                                            |
|---------------|--------------------------------------------------|
| verdict       | A detection result (`rogue one` or `benign one`) |
| landing_pages | An array of IP of landing pages                  |

## Notes

- This is just a PoC tool. I cannot guarantee the results with high confidence at the moment.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
