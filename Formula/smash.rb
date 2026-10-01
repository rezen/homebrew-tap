class Smash < Formula
  desc "Policy-controlled shell for install scripts"
  homepage "https://github.com/rezen/smash"
  url "https://github.com/rezen/smash/archive/refs/tags/v0.0.3.tar.gz"
  sha256 "276aa9b2ec690fc9429a1a5b6259ece0d2c25bce32b814b0b734be992c14adb9"

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
