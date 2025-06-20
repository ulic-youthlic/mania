default:
    @just --list

info:
    @echo JUST PATH: `which just`
    @echo GIT PATH: `which git`
    @echo CARGO PATH: `which cargo`
    @echo GREP PATH: `which grep`
    @echo XARGS PATH: `which xargs`
    @echo TYPOS PATH: `which typos`
    @echo SHFMT PATH: `which shfmt`
    @echo DPRINT PATH: `which dprint`
    @echo SHELLCHECK PATH `which shellcheck`

check: info typoCheck fmtCheck clippyCheck buildCheck docCheck testCheck

shCheck:
    shellcheck ./.envrc ./scripts/*

typoCheck:
    typos -c ./typos.toml

fmtCheck: rustFmtCheck justFmtCheck shFmtCheck dprintFmtCheck

fmt: rustFmt justFmt shFmt dprintFmt

buildCheck:
    cargo build --locked

clippyCheck:
    cargo clippy --locked --all-targets -- --deny warnings

docCheck:
    cargo doc --no-deps --locked

testCheck:
    cargo test --locked

dprintFmt:
    dprint fmt

dprintFmtCheck:
    dprint check

rustFmtCheck:
    cargo fmt --check

rustFmt:
    cargo fmt

justFmtCheck:
    just --unstable --fmt --check

justFmt:
    just --unstable --fmt

shFmt:
    git ls-files | grep -E '^scripts/.*$' | xargs shfmt -w -s -i 2

shFmtCheck:
    git ls-files | grep -E '^scripts/.*$' | xargs shfmt -s -i 2 -d

alias c := check
alias i := info
alias f := fmt
