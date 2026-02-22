class Mk < Formula
  desc "Build tool with Make's dependency-graph model, minus 48 years of accumulated pain"
  homepage "https://github.com/marcelocantos/mk"
  url "https://github.com/marcelocantos/mk/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "68e0abd82343361c83f3fd6551a2bf6772d61762ca4e2b5adc9f753a3d4ab014"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/mk"
    bash_completion.install "completions/mk.bash" => "mk"
    zsh_completion.install "completions/mk.zsh" => "_mk"
  end

  test do
    (testpath/"mkfile").write <<~EOS
      greeting = world

      hello.txt:
          echo $greeting > $target
    EOS
    system bin/"mk", "-n", "hello.txt"
  end
end
