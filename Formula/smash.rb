class Smash < Formula
  desc "Policy-controlled shell for install scripts"
  homepage "https://github.com/rezen/smash"
  url "https://github.com/rezen/smash/archive/refs/tags/v0.0.2.tar.gz"
  sha256 "7be6ef47ad7ff144835272581d574a0ba06a52cbc2e50dbab2f40a038bb25b89"

  depends_on "go" => :build

  def install
    # third_party/sh is a build product: the mvdan.cc/sh module pinned in go.mod,
    # trimmed and patched with patches/sh. The go.mod replace directive points at
    # it, so nothing builds until the upstream sync script has generated it. This
    # is the same step the upstream release workflow runs before building.
    system "sh", "tools/sync-sh.sh"

    ENV["CGO_ENABLED"] = "0"
    system "go", "build", *std_go_args, "./cmd/smash"
  end

  test do
    system bin/"smash", "-init-policy", "policy.yaml"
    assert_match "#script:", (testpath/"policy.yaml").read

    # A run recreates ./sandbox and points the script's HOME inside it, so the
    # directory the script makes lands there and the audit log records it.
    (testpath/"hello.sh").write <<~SH
      echo "hello from smash"
      mkdir -p "$HOME/made"
    SH
    assert_match "hello from smash", shell_output("#{bin}/smash -audit audit.yaml hello.sh")
    assert_match "create path ~/made", (testpath/"audit.yaml").read
    assert_path_exists testpath/"sandbox/home/made"
  end
end
