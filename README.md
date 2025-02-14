# Foundry Fund Me

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

## [Getting Started](https://book.getfoundry.sh/)

### Requirements
- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
    - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
    - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

### Quickstart
```bash
git clone https://github.com/Cyfrin/foundry-fund-me-cu
cd foundry-fund-me-cu
make
```

## Usage

### Deploy
```bash
forge script script/DeployFundMe.s.sol
```