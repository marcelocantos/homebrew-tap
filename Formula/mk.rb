class Mk < Formula
  desc "Build tool with Make's dependency-graph model, minus 48 years of accumulated pain"
  homepage "https://github.com/marcelocantos/mk"
  url "https://github.com/marcelocantos/mk/archive/refs/tags/v0.2.0.tar.gz"
  sha256 "b68562acf83cabd7fdcc218fb77f3d247e28921a3db4cf6fc3116341b8a4b9ee"
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
