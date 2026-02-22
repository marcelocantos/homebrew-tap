class Ged < Formula
  desc "ge development daemon — dashboard and bridge for game servers and players"
  homepage "https://github.com/marcelocantos/ge"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-darwin-arm64.tar.gz"
      sha256 "20f989a4a71d55dbb3ba263c0b77ae304835e8f9481e3c8edd4376a2435cc774"
    else
      url "https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-darwin-amd64.tar.gz"
      sha256 "7e552b94833a2f404f64bb2472375bd398a8c227f5c85ff2118c0a4ff813fb0e"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-linux-arm64.tar.gz"
      sha256 "4ead2bf57d654b6b3ae89b269ce16d991cbad1cd2cd9e152f46699452bc76bae"
    else
      url "https://github.com/marcelocantos/ge/releases/download/ged/v0.1.0/ged-0.1.0-linux-amd64.tar.gz"
      sha256 "c58243fc9381ca97fcd9817a2293291de9fa98163854cdcf8b8b11083835c9b3"
    end
  end

  def install
    bin.install "ged"
  end

  service do
    run [opt_bin/"ged"]
    keep_alive true
    log_path var/"log/ged.log"
    error_log_path var/"log/ged.log"
  end

  test do
    system bin/"ged", "--version"
  end
end
