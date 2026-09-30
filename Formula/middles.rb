class Middles < Formula
  desc "Policy-enforcing package registry proxy"
  homepage "https://github.com/rezen/middles"
  url "https://github.com/rezen/middles/archive/refs/tags/v0.2.2.tar.gz"
  sha256 "7ff6a199a4c08fb2f56a169d8dc63970f2d6bbf46eece39bdad34c7d9e414c14"
  license "MIT"

  depends_on "rust" => :build

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    ENV["LZMA_API_STATIC"] = "1"
    system "cargo", "install", *std_cargo_args

    # The service reads etc/middles/middles.toml. Homebrew never overwrites an
    # existing copy that differs; a new default lands beside it as
    # middles.toml.default instead.
    cp "middles.example.toml", "middles.toml"
    inreplace "middles.toml", 'path = "data/cache.sqlite3"', "path = \"#{var}/middles/cache.sqlite3\""
    pkgetc.install "middles.toml"
    pkgshare.install "middles.example.toml"
  end

  service do
    run [opt_bin/"middles", "--config", etc/"middles/middles.toml"]
    keep_alive true
    working_dir var/"middles"
    log_path var/"log/middles.log"
    error_log_path var/"log/middles.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/middles --version")
    system bin/"middles", "--check"
    system bin/"middles", "--config", etc/"middles/middles.toml", "--check"
  end
end
