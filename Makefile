# Tap-level checks. This repo ships no code: the product is Formula/*.rb, and
# the only failure that reaches a user is a formula that will not install.

FORMULAE := $(wildcard Formula/*.rb)

.PHONY: check
check: syntax urls   ## the installability gate — what CI blocks on

.PHONY: syntax
syntax:              ## every formula parses as Ruby
	@for f in $(FORMULAE); do ruby -c "$$f" > /dev/null || exit 1; done
	@echo "ruby -c: $(words $(FORMULAE)) formulae parse"

.PHONY: urls
urls:                ## every url "..." in every formula resolves (HTTP 200)
	@./scripts/check-formula-urls.sh

.PHONY: sha
sha:                 ## as `urls`, and the bytes match the declared sha256
	@./scripts/check-formula-urls.sh --sha

# Not part of `check`: these formulae are emitted by Homebrew Releaser from the
# source repos, so offences have to be fixed in the generators, not here.
.PHONY: style
style:               ## brew style (advisory — generated files, upstream fixes)
	@brew style Formula
