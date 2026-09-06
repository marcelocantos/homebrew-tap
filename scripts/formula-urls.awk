# Emit "<file>\t<line>\t<url>\t<sha256>" for every `url "..."` in a Homebrew
# formula, paired with the `sha256 "..."` that follows it ("-" when there is
# none, e.g. a url whose checksum lives elsewhere).

match($0, /url "[^"]+"/) {
  if (url != "") print file "\t" lineno "\t" url "\t-"
  file = FILENAME
  lineno = FNR
  url = substr($0, RSTART + 5, RLENGTH - 6)
  next
}

match($0, /sha256 "[^"]+"/) {
  if (url != "") {
    print file "\t" lineno "\t" url "\t" substr($0, RSTART + 8, RLENGTH - 9)
    url = ""
  }
  next
}

END {
  if (url != "") print file "\t" lineno "\t" url "\t-"
}
