# Foundry Pilled

Have you found yourself Foundry pilled but don't know where to start? 
This repo showcases many of the benefits Foundry could bring to your project!

# Getting Started

Installing and configuring Foundry is lightning fast. 

## Installation

Please install the following:

-   [Foundry / Foundryup](https://github.com/foundry-rs/foundry)
    -  Install `foundryup` with the following command or check the [official docs](https://book.getfoundry.sh/getting-started/installation)
    - `curl -L https://foundry.paradigm.xyz | bash`
    -   To install or update the Foundry components simply run `foundryup`
    -   This will install `forge`, `cast`, and `anvil`


## Configuration

Foundry configuration lives in `foundry.toml`. When adding foundry to an existing project, you probably want to remap the 
testing and the src folders. For more configuration options [check the docs](https://book.getfoundry.sh/config/).

# Features

Foundry comes with many features and is still under very active development.
For now, this repository will mainly focus on Forge, the testing component of Foundry.

## Forge

Some of the features we're using are tests `test`, the formatter `fmt`, the gas snapshot `snapshot` and coverage `coverage`.
For more information on Forge subcommands read the [official docs](https://book.getfoundry.sh/reference/forge/).
Our [CI](https://github.com/RensR/Foundry-pilled/blob/master/.github/workflows/test.yml) requires any PR to be formatted through forge and to have an up-to-date gas snapshot.

## CLI Commands

The following CLI command will be used very frequently. 


### Testing

```
forge test
```

or test a specific contract with

```
forge test --match-contract CONTRACT_NAME
```

### Formatter

```
forge fmt
```

### Gas Snapshot

```
forge snapshot
```

# Contributing

Contributions are always welcome!