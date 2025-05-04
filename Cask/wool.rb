cask "wool" do
  version "1.0.1"
  sha256 "c8b6e0dcc75b85f4ae05fe7ffc5be4fbfc0ebf90cdae85e34cacb7c2340e27bd"

  url "https://github.com/velocityzen/Wool/releases/download/#{version}/Wool-#{version}.zip"
  name "Wool"
  desc "App that makes cleaning your screen and keyboard a breeze"
  homepage "https://github.com/velocityzen/Wool"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: ">= :sequoia"

  app "Wool.app"

  zap trash: [
    "~/Library/Application Support/com.2dubs.wool",
    "~/Library/Application Support/CrashReporter/Wool_*.plist",
    "~/Library/Application Support/Wool",
    "~/Library/Caches/com.crashlytics.data/com.2dubs.wool",
    "~/Library/Caches/com.2dubs.wool",
    "~/Library/Preferences/com.2dubs.wool.plist",
  ]
end
