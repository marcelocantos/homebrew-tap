class Mk < Formula
  desc "Build tool with Make's dependency-graph model, minus 48 years of accumulated pain"
  homepage "https://github.com/marcelocantos/mk"
  version "0.3.0"
  license "Apache-2.0"

  if OS.mac? && Hardware::CPU.arm?
    url "https://github.com/marcelocantos/mk/releases/download/v0.3.0/mk-v0.3.0-darwin-arm64.tar.gz"
    sha256 "69967e3d6d6898b83d101f7d76a5977a6f62bb03413b1e3c4ba0974748018a48"
  end

  if OS.linux? && Hardware::CPU.intel?
    url "https://github.com/marcelocantos/mk/releases/download/v0.3.0/mk-v0.3.0-linux-amd64.tar.gz"
    sha256 "a50bbb2284fbc7598e5f1e4325be1987fc1db63415cdb5c4ab738b22c09c8a54"
  end

  if OS.linux? && Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
    url "https://github.com/marcelocantos/mk/releases/download/v0.3.0/mk-v0.3.0-linux-arm64.tar.gz"
    sha256 "0bbc3f006f3d018dedff16920b6dbf2fee44fb94f42452da2a564813e52282ce"
  end

  def install
    bin.install "mk"
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
