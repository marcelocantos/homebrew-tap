class Mk < Formula
  desc "Build tool with Make's dependency-graph model, minus 48 years of accumulated pain"
  homepage "https://github.com/marcelocantos/mk"
  url "https://github.com/marcelocantos/mk/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "6c52f0bbb07dc2dc76cb0fb32fb12ad3bff95ed4ce6b1d814e587859faf081ef"
  license "Apache-2.0"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/mk"
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
