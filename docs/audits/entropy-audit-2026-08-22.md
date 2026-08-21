# Entropy audit — homebrew-tap

Date: 2026-08-22
Mode: full (entropy + hygiene)
Skill: `entropy-audit` + `hygiene`

## Executive summary

- **Snapshot (workspace):** `/Users/marcelo/work/github.com/marcelocantos/homebrew-tap`, branch `master`, HEAD `7d067014e0b38a46ee94aeb6569b740b44597405` (`chore: brew formula update for spyder v0.53.0`, 2026-06-01). Working tree clean (`git status --porcelain=v1 -b`: `## master...origin/master [behind 36]`). No `AGENTS.md`, `CLAUDE.md`, `hygiene.yaml`, `.github/`, or `LICENSE`.
- **Published tap (shipped path):** GitHub `master` and the live Homebrew checkout `/opt/homebrew/Library/Taps/marcelocantos/homebrew-tap` are both `f9fc3e930c7498a9fc255d97725e23b4a2372414` (`chore: brew formula update for spyder v0.80.0`, 2026-08-21). Local `origin/master` is stale at `47bf4d2` (2026-06-30). This audit does not treat clone lag as a repo defect; published-tap evidence is used wherever the user-visible `brew install` path differs.
- **Scope:** all 19 workspace formulae under `Formula/` plus `README.md`. Additional published-only formula: `Formula/blurter.rb`. No generated/vendored/fixture trees were skipped: Homebrew Releaser output *is* the shipped product.
- **Headline mechanism:** this repository is a generated artifact sink. Nineteen (published: twenty) binary formulae are committed by `homebrew-releaser` from N source repos; one formula (`ged`) is hand-maintained and currently 404s on fetch. Two post-rename GitHub repos still have a second, frozen formula under the old name, so `brew install` can silently deliver months-old binaries of the same project. Nothing in CI runs `brew audit --online` or `brew fetch`, so those failures stay green.
- **Highest-consequence findings:** ENT-001 (`ged` download 404 — `brew fetch` fails); ENT-002 (canopy/sawmill and tern/pigeon are the same GitHub repos at drifted versions, with no `formula_renames.json` / `deprecate!`); ENT-003 (no GitHub Actions, no tap-level oracle).
- **Unverified residue:** `brew install` / `brew test` not executed for the full matrix (would mutate the host); bottle SHA-256s not recomputed against release assets; Intel/source-fallback install failure inferred from formula shape, not reproduced on an Intel Mac.

## Scope and exclusions

In scope:

- `Formula/*.rb` (workspace 19 files; published tap adds `blurter.rb`)
- `README.md` (Homebrew Releaser `project_table_*` region)
- GitHub repo settings (Actions, license, branch protection, rulesets)
- Live Homebrew tap checkout used by this machine (`brew --repo marcelocantos/tap`)

Excluded as out of this repo (named, not silent):

- Homebrew Releaser config and release workflows inside each source project
- Binary contents of GitHub release tarballs (SHA-256 not re-hashed)
- The `squz/ge` transfer target, except as the redirect destination of `ged` URLs

Languages detected: Homebrew Ruby DSL plus a 7-line POSIX `sh` wrapper inside `vellum.rb`. No Python, Go, C/C++, Rust, SQL, or web app in this tree. `bash.md` was read for the vellum wrapper (thin `export PATH` + `exec` — appropriate glue).

## Commands run

| Command | Version / notes | Exit | Shipped vs auxiliary | Limitation |
|---|---|---|---|---|
| `git rev-parse HEAD`; `git status --porcelain=v1 -b` | git; HEAD `7d06701`; clean; behind origin 36 | 0 | provenance | Local `origin/master` is not GitHub HEAD |
| `git ls-files`; `git log --oneline -20`; churn / authors | 270 `homebrew-releaser` commits, 13 human | 0 | history | — |
| `ruby -c Formula/*.rb` | ruby 4.0.5 | 0 (19/19) | auxiliary syntax | Does not load Homebrew `Formula` API |
| `brew --version` | Homebrew 6.0.18-96-gac9e7ac | 0 | tool identity | — |
| `brew style marcelocantos/tap` | inspects **live tap** (21 files, includes `blurter.rb`) | 1 (21 offenses) | auxiliary style | Not the workspace snapshot; style ≠ installability |
| `brew audit --formula marcelocantos/tap/<name>` | live tap versions | problems reported (style / redundant `version`) | auxiliary | Does not download URLs without `--online` |
| `brew audit --online --formula marcelocantos/tap/ged` | live tap `ged` 0.1.0 | problems include HTTP 404 | shipped-adjacent | Confirmed URL unreachability |
| `brew fetch --formula marcelocantos/tap/ged` | live tap | **1** — `curl: (56) ... 404` | **shipped download path** | Did not attempt install |
| `curl -sI -L` on bottle and `ged` URLs | HTTP 200 for representative bottles; **404** for all four `ged` URLs | 0 (curl) | shipped URL | HEAD only |
| `gh api repos/marcelocantos/{canopy,sawmill,pigeon,tern,ge,homebrew-tap,...}` | canopy id `1201873754` == sawmill; pigeon id `1188490610` == tern; Actions `total_count: 0`; license `null`; branch protection 404; rulesets `[]` | 0 | published identity | `gh` uses GitHub HEAD |
| `gh api repos/marcelocantos/homebrew-tap/contents/Formula/*.rb` | published formulae | 0 | published snapshot | Not written to workspace |
| Python inventory of versions / platforms | stdlib | 0 | auxiliary | — |
| `ls hygiene.yaml` | absent | 2 | hygiene | Validator not invoked (no file) |

`brew audit [path]` is disabled by current Homebrew; audits used formula names against the live tap. `HOMEBREW_NO_AUTO_UPDATE=1` was set. No analyzers were installed.

## Observed architecture

```
N source GitHub repos
  |  Homebrew Releaser (commit as homebrew-releaser@example.com)
  v
github.com/marcelocantos/homebrew-tap   (this repo: Formula/*.rb + README table)
  |
  v
brew tap marcelocantos/tap   →  brew install <formula>  (binary tarball per OS/arch)
```

**Declared (comments + README):** formulae are generated; `brew install marcelocantos/tap/<formula>`; README table is bounded by `<!-- project_table_start -->` / `<!-- project_table_end -->`.

**Observed:**

- Single package: `Formula/<name>.rb`. No `cmd/`, libraries, tests directory, or CI.
- 18/19 workspace formulae start with `# This file was generated by Homebrew Releaser. DO NOT EDIT.` `ged.rb` does not.
- Typical generated shape: top-level source `url` (GitHub archive) + SHA, then `on_macos { on_arm { url bottle } }` and usually `on_linux` intel/arm bottles, `def install` of prebuilt binaries, `test do; system bin/"name", "--version"`.
- Customisation islands (still generated): `spyder` service + caveats + multi-bin install; `mnemo` `depends_on` + service PATH; `vellum` `depends_on` + caveats + `bin` wrapper; `mcpbridge`/`sawmill`/`blurter` (published) services; `ytt` `libexec` + deps; `cv` completions + a real dry-run test; `pageflip` / `sysinfo-mcp` / `spyder` macOS-arm only.
- Public surface: the Homebrew formula names. No HTTP API in-repo.
- Direction: source repo → tap. No cycles. Fan-in hub: the Releaser commit identity.
- Enforcement in-repo: none. `brew style` / `brew audit` exist as host tools and are not wired.

**Declared ∩ observed:** generated binary formulae in `Formula/`, README install instructions, Apache-2.0 *on most formula DSL `license` lines*.

**Inferred:** tap is Apple Silicon–first (no `darwin-amd64` bottles except `ged`); Linux bottles are opportunistic; old names (`canopy`, `tern`) were left in place after GitHub repo renames.

**Contradictions:** `ged` homepage `marcelocantos/ge` 301s to `squz/ge`; formula is not generated; URLs 404. `canopy` homepage is the sawmill repo; `tern` homepage is the pigeon repo. Tap has no root `LICENSE` while formulae claim Apache-2.0. Formula `test do` blocks exist but have no CI runner.

**Unknown intent:** whether `canopy`/`tern` should remain aliases; whether `ged` still belongs in this tap after the `ge` transfer; whether Intel Macs are a supported install target.

## Dimension vector

| Dimension | State | Evidence summary | Change from baseline |
|---|---|---|---|
| Architecture topology | concern | One-dir generated tap is coherent; a second, hand-rolled authorship path (`ged.rb`) and leftover rename formulae break the single-pipeline model | n/a (first audit) |
| Redundancy / sources of truth | concern | canopy≡sawmill and tern≡pigeon (same GitHub repo ids) at different pinned versions; formula text is N generated copies of one Releaser template | n/a |
| Change amplification | concern | Tap-wide convention (PATH, component order, `deprecate!`) requires edits in N source-repo Releaser configs, then a release | n/a |
| Local code quality | concern | `ruby -c` clean; `brew style` 21 offenses on the live tap (order, line length, dual `on_macos`, `ENV["HOME"]`); hardcoded `/opt/homebrew` in `spyder` | n/a |
| Correctness / verification | critical | `brew fetch ged` 404s on the shipped URL; no Actions; formula tests never run in CI | n/a |
| Security / dependencies | concern | No secret-scan/CI; service PATH prepends user-writable `~/.cargo`, `~/.py`, `~/.claude/local`; no tap SBOM (binaries are upstream) | n/a |
| Build / release / operations | concern | Releaser keeps most published formulae at latest tag; `ged` is outside that loop; no branch protection; no `brew test-bot` | n/a |
| Documentation / governance | concern | README table matches workspace formula names; no LICENSE file (GitHub `licenseInfo: null`); no hygiene; no CODEOWNERS; no `formula_renames.json` | n/a |

Do not collapse this vector to a score.

## Findings

### ENT-001: `ged` bottle URLs 404 — `brew fetch` fails

- **Priority:** P0
- **Dimensions:** Correctness / verification; Build / release / operations
- **Status:** observed fact
- **Evidence:**
  - `Formula/ged.rb:9` (and `:12`, `:19`, `:22`) pin `https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-<os>-<arch>.tar.gz`.
  - `Formula/ged.rb:1-4` is hand-written (no Releaser banner); homepage `https://github.com/marcelocantos/ge` (`Formula/ged.rb:3`).
  - `curl -sI -L` on the darwin-arm64 URL: 301 → `https://github.com/squz/ge/releases/download/ged/v0.1.0/...` then **HTTP 404**.
  - `brew fetch --formula marcelocantos/tap/ged` exit 1: `Download failed: https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-darwin-arm64.tar.gz` / `curl: (56) The requested URL returned error: 404`.
  - `brew audit --online --formula marcelocantos/tap/ged`: `Stable: The source URL ... is not reachable (HTTP status code 404)`.
  - GitHub API lists tag `ged/v0.1.0` assets, but `browser_download_url` uses `.../download/untagged-a348094a50016adbbc78/...`; that untagged URL also 404s.
  - Identical `ged.rb` on GitHub HEAD `f9fc3e9` and workspace `7d06701`.
- **Mechanism:** a draft/untagged release plus a repo transfer (`marcelocantos/ge` → `squz/ge`) left the formula pointing at a path GitHub no longer serves. Homebrew has no compile fallback, so install is hard-fail. Because `ged` is not on the Releaser pipeline, later `ge` tags (`v0.91.0` and peers, no `ged-*` assets) never refresh this formula.
- **Blast radius:** anyone running `brew install ged` / `brew upgrade ged` / `brew fetch ged`. Other formulae are unaffected.
- **Counterevidence checked:** `brew info marcelocantos/tap/ged` still advertises the formula (metadata ≠ fetchability). SHA-256s are present but unused if the GET 404s. `ge` still has a `ged/v0.1.0` release object in the API; the object is not a working download. Do not treat `ge` `v0.91.0` as a 90-version lag of the same artifact — those tags have empty asset lists.
- **Smallest coherent remediation:** either (1) publish a real tagged `ged` release with downloadable assets and retarget the four URLs, or (2) `disable!` / delete `Formula/ged.rb` if the sidecar is abandoned. If `ge` moved to `squz`, update `homepage` to the surviving URL. Prefer putting `ged` on Homebrew Releaser so the next tag cannot rot invisibly.
- **Verification:** `brew fetch --formula marcelocantos/tap/ged` exits 0; `brew audit --online --formula marcelocantos/tap/ged` no longer reports 404.
- **Ratchet candidate:** CI job `brew audit --online --tap marcelocantos/tap` (or per-formula `brew fetch`) on every push.

### ENT-002: Rename residue — two formulae per renamed GitHub repo, versions drifted

- **Priority:** P1
- **Dimensions:** Redundancy / sources of truth; Architecture topology; Change amplification
- **Status:** observed fact
- **Evidence:**
  - `gh api repos/marcelocantos/canopy` and `.../sawmill` both return `id: 1201873754`, `full_name: marcelocantos/sawmill`. Formulae still differ: `Formula/canopy.rb:7-9` homepage `.../canopy`, version `0.3.0`; `Formula/sawmill.rb:14-16` homepage `.../sawmill`, version `0.14.0` (published tap: sawmill `0.18.0`, canopy still `0.3.0`). Latest sawmill/canopy release tag is `v0.18.0`.
  - `gh api repos/marcelocantos/tern` and `.../pigeon` both return `id: 1188490610`, `full_name: marcelocantos/pigeon`. `Formula/tern.rb:7-9` version `0.12.0`; `Formula/pigeon.rb:7-9` version `0.23.0` (published: pigeon `0.32.0`, tern still `0.12.0`). Latest pigeon/tern release tag is `v0.32.0`.
  - Identical `desc` strings: canopy and sawmill both "Mcp server for ast-level multi-language code transformations"; tern/pigeon descriptions differ only by a parenthetical language list.
  - No `formula_renames.json`, no `Aliases/`, no `deprecate!` / `disable!` in any formula (workspace and GitHub tree).
  - Canopy `v0.3.0` and tern `v0.12.0` bottle URLs still HTTP 200 — installs succeed and deliver stale binaries, not errors.
  - Contrast that worked: `a490036` removed `Formula/mk.rb` after rename to `cv`; `f1943df` removed obsolete `cworkers.rb`. Those old names are gone; these two pairs were not.
- **Mechanism:** GitHub repo rename keeps old URLs as aliases, so Homebrew Releaser can keep committing under the new name while the old formula file is never updated or removed. Users who `brew install canopy` or `brew install tern` get a frozen snapshot of sawmill/pigeon. A bugfix in sawmill 0.18 must be repeated as a canopy bump that will not happen. README still lists both names (`README.md:17` canopy, `README.md:28` sawmill in the workspace table).
- **Blast radius:** anyone installing the old names; docs and the generated project table keep advertising them; two binary names (`canopy` vs `sawmill`, `tern` vs `pigeon`) can be installed side by side from the same codebase.
- **Counterevidence checked:** bottles for the old versions still exist (not a 404). Binary names differ, so there is no `conflicts_with` clash today. mk→cv shows the intended end state (delete old formula) was known. No evidence the old names are still the public brand.
- **Smallest coherent remediation:** add tap `formula_renames.json` (`canopy` → `sawmill`, `tern` → `pigeon`) and `deprecate!` (then later `disable!`) the old formulae, *or* delete them as with `mk.rb`. Stop Releaser from being able to recreate the old names.
- **Verification:** `gh api repos/marcelocantos/canopy --jq .id` equals sawmill id ⇒ `brew info canopy` prints a rename/deprecation pointing at sawmill; `brew audit` fails if a second live formula targets the same GitHub repo id at a lagged version.
- **Ratchet candidate:** a small CI script: for each formula homepage, resolve GitHub repo `id`; fail if two formulae share an id and neither is deprecated. Plus a `file: formula_renames.json` hygiene item once added.

### ENT-003: No CI, so shipped fetch/audit oracles never run

- **Priority:** P1
- **Dimensions:** Correctness / verification; Build / release / operations; Documentation / governance
- **Status:** observed fact
- **Evidence:**
  - `gh api repos/marcelocantos/homebrew-tap/actions/workflows` → `{total_count: 0, workflows: []}`.
  - No `.github/` on workspace or GitHub tree.
  - Every generated formula has `test do` (e.g. `Formula/bullseye.rb:36-38`, `Formula/cv.rb:38-46`) but nothing invokes `brew test`.
  - `brew audit --online` is what detected ENT-001; it is not a required check. Branch protection: HTTP 404. Rulesets: `[]`.
- **Mechanism:** Releaser pushes formula SHA/version bumps directly to `master`. A 404, a drifted rename formula, or a `brew style` regression cannot fail the merge because there is no merge gate.
- **Blast radius:** all formulae; ENT-001 survived from 2026-02-22 (`b348b3a` added `ged.rb`) through 2026-08-21.
- **Counterevidence checked:** `ruby -c` is green (syntax only). Host-side `brew style`/`brew audit` exist but are optional and were not part of the repo. Releaser *does* keep non-rename formulae at latest published tags on GitHub HEAD (bullseye 0.46, spyder 0.80, mnemo 0.86, … match `releases/latest`).
- **Smallest coherent remediation:** one GitHub Actions workflow on push: `brew tap` this repo (or checkout-as-tap) then `brew audit --online --tap marcelocantos/tap` and `brew fetch` each formula. Optionally `brew test` on macos-14 arm64 for a thin slice.
- **Verification:** a deliberately 404 URL in a throwaway formula fails CI; reverting it goes green.
- **Ratchet candidate:** hygiene `ci_job: audit.yml#audit` once the workflow exists; `floors.correctness: 2`.

### ENT-004: Two authorship pipelines — generated Releaser vs hand-rolled `ged`

- **Priority:** P2
- **Dimensions:** Architecture topology; Change amplification
- **Status:** observed fact
- **Evidence:**
  - 18/19 workspace files contain `Formula/bullseye.rb:4` (and peers): `generated by Homebrew Releaser. DO NOT EDIT.`
  - `Formula/ged.rb` has no banner, no `# typed: true`, uses `Hardware::CPU.arm?` instead of `on_arm`, and is the only formula with darwin-amd64 bottles (`Formula/ged.rb:11-13`). Last commit: `b348b3a` (2026-02-22), author Marcelo Cantos, never touched by Releaser.
  - Style/component-order fixes in Releaser templates cannot reach `ged`; conversely, a tap-wide `deprecate!` policy cannot be expressed once.
- **Mechanism:** invariants live in N upstream templates plus one snowflake. The snowflake is exactly the formula whose URLs rotted (ENT-001).
- **Blast radius:** any tap-wide policy (arch flags, license line, audit cleanliness, service PATH).
- **Counterevidence checked:** the Releaser path is healthy for the other formulae (published versions match latest tags except the rename aliases). Hand-rolling is valid Homebrew; it is the missing refresh loop that hurts, not the Ruby style.
- **Smallest coherent remediation:** generate `ged` via Releaser from `ge`, or drop it from the tap. Do not add a second hand-rolled formula.
- **Verification:** `rg -L 'generated by Homebrew Releaser' Formula` is empty.
- **Ratchet candidate:** `file` evidence that every `Formula/*.rb` matches `Homebrew Releaser`.

### ENT-005: Service/wrapper PATH is host-personal, not prefix-portable

- **Priority:** P2
- **Dimensions:** Local code quality; Security / dependencies; Change amplification
- **Status:** observed fact (PATH contents); inference (exploitability on a personal machine)
- **Evidence:**
  - `Formula/spyder.rb:11` hardcodes `/opt/homebrew/bin:/opt/homebrew/sbin:...` (published tap also sets `SPYDER_ADDR: ":3030"` on the same line).
  - `Formula/mnemo.rb:18` interpolates `ENV["HOME"]` into `~/.cargo/bin`, `~/.local/bin`, `~/.py/bin`, `~/go/bin`, `~/.claude/local` for the LaunchAgent PATH (`brew style`: `Style/EnvHome`).
  - `Formula/vellum.rb:54-61` writes a POSIX wrapper that prepends `$HOME/.cargo/bin`, `$HOME/.py/bin`, `$HOME/go/bin` at **runtime**.
  - Published `jevons.rb` service PATH hardcodes `/opt/homebrew/...` plus `Dir.home` cargo/py/go bins (workspace `jevons.rb` has no service block).
- **Mechanism:** brew services inherit a stripped PATH. The formulae compensate by baking *this owner's* toolchain layout into the plist/wrapper. `spyder` ignores `HOMEBREW_PREFIX` (wrong on Linuxbrew / Intel `/usr/local`). User-writable directories ahead of `/usr/bin` mean a `gh`/`node` planted in `~/.cargo/bin` wins when the daemon starts. `mnemo.rb:18` is evaluated when the formula is loaded (install-time home), not when the plist later runs as a different user.
- **Blast radius:** spyder/mnemo/vellum/jevons daemons and the vellum CLI; Linux or non-`/opt/homebrew` prefixes; any future formula that copies the snippet.
- **Counterevidence checked:** `mnemo` and `vellum` correctly use `HOMEBREW_PREFIX` for brew bins. Spyder has no Linux bottles (`Formula/spyder.rb` macOS-arm only), so the Linux prefix bug is latent. This is a personal tap; the PATH is likely deliberate for MCP daemons. `bash.md` boundary: the vellum wrapper is thin exec glue, not a shell program that should be rewritten.
- **Smallest coherent remediation:** PATH = `"#{HOMEBREW_PREFIX}/bin:#{HOMEBREW_PREFIX}/sbin:/usr/bin:/bin"` plus declared `depends_on` for tools the daemon actually needs. Drop personal `~/.py` / `~/.claude/local`. Keep a documented extra PATH only if a named, tested tool lives there.
- **Verification:** `brew style` `Style/EnvHome` clean; a unit assertion that no formula string-matches `/opt/homebrew` or `/.py/bin`.
- **Ratchet candidate:** `rg` CI step forbidding `/opt/homebrew` and `ENV["HOME"]` in `Formula/`.

### ENT-006: Prebuilt formulae with a source-tarball fallback and no `arch` constraint

- **Priority:** P2
- **Dimensions:** Correctness / verification; Architecture topology
- **Status:** inference (not executed on Intel)
- **Evidence:**
  - Typical generated formula (`Formula/bullseye.rb:8-17`): top-level `url` is a GitHub **source** archive; `on_macos { on_arm { url bottle } }` overrides only on Apple Silicon. No `on_intel` / `darwin-amd64` bottle except `ged`.
  - `def install` is `bin.install "bullseye"` (`Formula/bullseye.rb:32-33`) with no `depends_on` compiler and no `cargo`/`make` build.
  - macOS-arm-only bottles: `pageflip.rb`, `sysinfo-mcp.rb`, `spyder.rb` (no `on_linux` at all).
  - No `depends_on arch: :arm64` (or equivalent) in any formula.
- **Mechanism:** on darwin-x86_64 Homebrew uses the top-level source URL, then `bin.install` looks for a binary that is not in the source tarball. Failure mode is an opaque install error rather than "unsupported architecture".
- **Blast radius:** Intel Mac (and any OS/arch without a bottle block). Owner fleet is arm64, so this may be accepted.
- **Counterevidence checked:** published Releaser configs simply may not build darwin-amd64. `ged` *does* ship amd64 bottles, showing the pattern is known. Not reproduced on Intel hardware (residue).
- **Smallest coherent remediation:** if unsupported, declare it (`depends_on arch: [:arm64]` or a `on_intel { odie "..." }`). If supported, add bottles. Do not leave a source URL that cannot install.
- **Verification:** `brew fetch --force` under `HOMEBREW_BOTTLE_ARCH` / an Intel runner fails with an explicit unsupported message, not a missing-file `bin.install`.
- **Ratchet candidate:** CI matrix job on `macos-13` x86_64 that expects a declared skip, or a grep that every formula with `bin.install` of a prebuilt also has a matching bottle `url` per advertised OS.

### ENT-007: Tap has no LICENSE, protection, hygiene, or ignore file

- **Priority:** P2
- **Dimensions:** Documentation / governance; Security / dependencies
- **Status:** observed fact
- **Evidence:**
  - `gh api repos/marcelocantos/homebrew-tap --jq .license` → `null`. No root `LICENSE`. Formulae (except rustuml) declare `license "Apache-2.0"` in DSL (e.g. `Formula/bullseye.rb:11`).
  - Branch protection 404; rulesets `[]`; `hasWikiEnabled: true` on a formulae-only repo.
  - No `.gitignore`, no `CODEOWNERS`, no `hygiene.yaml`, no `AGENTS.md`.
- **Mechanism:** GitHub license detection keys off a root license file, so the tap looks unlicensed while redistributing Apache-2.0 binaries. Direct pushes to `master` (Releaser) have no required check (compounds ENT-003).
- **Blast radius:** legal metadata for consumers; no review gate for a compromised Releaser token rewriting bottles.
- **Counterevidence checked:** upstream projects are Apache-2.0 (spot-check: rustuml GitHub license is Apache-2.0 even though the formula omits the DSL). Public tap, issues enabled. Releaser-only authors on almost all commits is bus-factor by design, not accidental.
- **Smallest coherent remediation:** add `LICENSE` (Apache-2.0) matching the formulae; add `hygiene.yaml` that records the real floors (honest zeros where CI is absent) rather than pretending; consider a ruleset requiring the audit workflow from ENT-003.
- **Verification:** GitHub `license.spdx_id == Apache-2.0`; `hygiene_check.py` exit 0.
- **Ratchet candidate:** hygiene items `file: LICENSE`, `gh_setting` for default-branch protection once a check exists.

### ENT-008: `rustuml` formula omits `license`

- **Priority:** P3
- **Dimensions:** Documentation / governance; Local code quality
- **Status:** observed fact
- **Evidence:** `Formula/rustuml.rb:5-10` jumps from `version`/`sha256` to `on_macos` with no `license` line. `rg -L '^  license '` would be this file. Upstream `gh api repos/marcelocantos/rustuml --jq .license.spdx_id` is `Apache-2.0`. Unchanged on GitHub HEAD.
- **Mechanism:** `brew info rustuml` will not report a license; tap-wide "all formulae Apache-2.0" is already false.
- **Blast radius:** one formula's metadata.
- **Counterevidence checked:** not a license-file problem in the rustuml repo; Releaser config likely omitted the field.
- **Smallest coherent remediation:** set `license "Apache-2.0"` in the rustuml Releaser config and cut a formula refresh (do not hand-edit the generated file).
- **Verification:** `brew info rustuml` shows Apache-2.0; `rg -L 'license ' Formula` empty.
- **Ratchet candidate:** `brew audit` already can flag missing licenses under stricter flags; add `--strict` to the ENT-003 job.

### ENT-009: Releaser output systematically fails `brew style`

- **Priority:** P3
- **Dimensions:** Change amplification; Local code quality
- **Status:** observed fact
- **Evidence:** `brew style marcelocantos/tap` — 21 files, 21 offenses (live tap). Recurring classes: `FormulaAudit/ComponentsOrder` (`desc` after `depends_on`/`service`/`caveats` — `Formula/mnemo.rb:21` vs `depends_on` at line 6; `Formula/spyder.rb:39` vs caveats at 14; `Formula/vellum.rb` same shape), `Layout/LineLength` on PATH lines, `Style/Semicolon` on `Formula/spyder.rb:54`, redundant explicit `version` vs URL, published `blurter.rb` two `on_macos` blocks. Workspace `ruby -c` still passes.
- **Mechanism:** extra Homebrew DSL (service, depends_on, caveats) is prepended before `desc`/`homepage` by the generator, so every customised formula fails component order. Fixing one formula by hand is overwritten on the next release.
- **Blast radius:** `brew style` cleanliness; not installability.
- **Counterevidence checked:** Homebrew accepts these formulae (`brew info` works). Offenses are Correctable. Not a reason to fork the generator in this tap.
- **Smallest coherent remediation:** fix the Releaser extra-content injection order in the source projects (or a shared template) so `desc`/`homepage`/`url` stay first.
- **Verification:** `brew style marcelocantos/tap` exit 0.
- **Ratchet candidate:** CI `brew style --tap marcelocantos/tap`.

### ENT-010: Workspace `jevons` installs a generic `remote` binary (already gone on GitHub HEAD)

- **Priority:** P3
- **Dimensions:** Local code quality
- **Status:** observed fact on snapshot `7d06701`; counterevidence on published tap
- **Evidence:** `Formula/jevons.rb:32-34` `bin.install "remote" => "remote"` at jevons 0.4.0. Published formula is 0.13.0 and only installs `jevonsd`.
- **Mechanism:** a generic name in `$(brew --prefix)/bin` shadows any other `remote`. Published tap already dropped it.
- **Blast radius:** only consumers of this stale clone / old bottle. Not the 2026-08-21 published tap.
- **Counterevidence checked:** GitHub HEAD jevons 0.13.0.
- **Smallest coherent remediation:** none in the tap beyond staying on published HEAD. Do not resurrect `remote` as an unprefixed bin name.
- **Verification:** `rg 'bin.install "remote"' Formula` empty on `f9fc3e9`.
- **Ratchet candidate:** none (closed on shipped path).

## Redundancy and competing-source-of-truth inventory

| Fact | Authorities | Drift already? |
|---|---|---|
| Formula version/SHA/url | Each source repo's release + Releaser commit in this tap | Published tap matches `releases/latest` except canopy, tern, ged |
| Project description | Formula `desc` and README table (Releaser-generated, truncated ~80 chars) | Same generator; truncated vs upstream README |
| GitHub project identity | Formula `homepage` vs actual repo after rename | canopy/tern homepages are aliases of sawmill/pigeon |
| Installer name after rename | `Formula/canopy.rb` vs `Formula/sawmill.rb`; `tern` vs `pigeon`; (healthy) `mk` deleted for `cv` | Yes — versions 0.3.0 vs 0.18.0 and 0.12.0 vs 0.32.0 |
| License | Per-formula `license` DSL vs missing root LICENSE vs upstream repo license | rustuml DSL missing; GitHub tap license null |
| Service PATH policy | Copied snippets per formula (spyder hardcoded prefix; mnemo `ENV["HOME"]`; vellum wrapper `$HOME`) | Three incompatible variants |
| `ged` artifacts | Hand-maintained formula vs `ge` releases vs `squz/ge` transfer | URLs 404 |
| Tap contents | Workspace `7d06701` vs GitHub/brew `f9fc3e9` | Clone lag only (not a product SoT) |

Deliberate duplication: N near-identical generated formulae. Coupling them into a tap-local generator would fight Homebrew Releaser. Keep one generator; do not DRY the Ruby by hand.

## Healthy structure worth retaining

- **Generated-sink shape.** `Formula/` + README table is the right size for a tap. `DO NOT EDIT` banners match the commit graph (270/284 commits are `homebrew-releaser`).
- **Per-arch SHA-256 bottles** for darwin-arm64 and (usually) linux-amd64/arm64. Spot-check bottle URLs HTTP 200 (bullseye 0.29/0.46, spyder 0.53/0.80, ytt 0.5/0.11, sawmill 0.18, pigeon 0.32).
- **Completed removals:** `Formula/mk.rb` → `cv` (`a490036`); `Formula/cworkers.rb` removed when the project archived (`f1943df`). Those are the rename/retirement pattern to reuse for canopy/tern/ged.
- **cv test is a real dry-run** (`Formula/cv.rb:38-46`) rather than `--version` only.
- **ytt install** uses `libexec` + symlink (`Formula/ytt.rb:36-38`) and asserts the version string.
- **No secrets, no lockfiles, no extra config formats.** Ruby syntax clean on all 19 workspace files.
- **Published non-alias formulae track latest tags** (bullseye, spyder, mnemo, jevons, vellum, ytt, sqldeep, mcpbridge, crosshair, blurter, pigeon, sawmill).

## Hygiene posture

`hygiene.yaml` is **absent**. Hygiene posture not declared.

The `hygiene` validator was not run (skill: do not initialize on a missing file). There is therefore no per-dimension held-tier vector, no floors, and no drift report.

Overlap with entropy (for when hygiene is onboarded): ENT-003 maps to `correctness` CI; ENT-001 to a `command: brew fetch` / `brew audit --online` evidence; ENT-007 to `file: LICENSE` and `governance`; ENT-008 to formula license; ENT-002 to a custom command over GitHub repo ids. Do not ratchet `hygiene.yaml` from this audit.

## Oracle coverage and residue

| Property | Decided by | Result |
|---|---|---|
| `ged` tarball is downloadable | `brew fetch` (shipped) + `brew audit --online` | **FAIL** (ENT-001) |
| Formula Ruby parses | `ruby -c` (auxiliary) | PASS (19/19 workspace) |
| Homebrew style | `brew style` on live tap (auxiliary) | FAIL 21 offenses (ENT-009) |
| Formulae match latest GitHub tags | `gh api releases/latest` vs formula `version` | PASS on published tap except canopy, tern, ged |
| canopy/tern are the same repos as sawmill/pigeon | GitHub repo `id` | PASS (identity); FAIL (single SoT) |
| Bottle SHA-256 matches asset bytes | not run | residue |
| `brew test` per formula | not run (would install) | residue |
| Intel/source-fallback install | inferred from DSL | residue (ENT-006) |
| Branch protection / Actions present | `gh api` | absent (ENT-003, ENT-007) |
| Hygiene floors hold | n/a | undeclared |

**Owner residue** (intent, not mechanical leftovers):

1. Keep `canopy`/`tern` as deprecated aliases, or delete like `mk`?
2. Does `ged` still belong in `marcelocantos/homebrew-tap` after `ge` moved to `squz/ge`?
3. Are Intel Macs a supported install target?
4. Is injecting `~/.cargo` / `~/.py` / `~/.claude/local` into brew-services PATH an accepted personal-machine risk?

## Remediation sequence

1. **Oracle seam:** add a GitHub Actions workflow that `brew audit --online --tap marcelocantos/tap` and `brew fetch`s each formula (ENT-003). This would have failed closed on ENT-001.
2. **Fix or remove `ged`** (ENT-001, ENT-004). Do not leave a advertised 404. Prefer Releaser or deletion over another hand edit.
3. **Converge rename aliases** (ENT-002): `formula_renames.json` + `deprecate!` canopy→sawmill and tern→pigeon (or delete). Mirror the `mk`/`cworkers` precedent.
4. **PATH policy** (ENT-005) in the Releaser extra snippets: `HOMEBREW_PREFIX` only; drop `/opt/homebrew` and personal homes.
5. **Declare arch support** (ENT-006) so unsupported platforms fail with a message.
6. **LICENSE + rustuml `license` DSL** (ENT-007, ENT-008).
7. **Ratchet** the audit workflow (and, only if later requested, `hygiene.yaml`). Re-run this audit against HEAD `f9fc3e9` (or newer) with the same command set.

Do not apply these changes in this audit.
