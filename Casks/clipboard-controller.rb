cask "clipboard-controller" do
  version "1.2.0"
  sha256 "84bc600eaed7344943d7303b190a457cf637b8558943e3f2d1c08ec416efb4fa"

  url "https://github.com/fballiano/clipboard-controller/releases/download/v#{version}/clipboard-controller-#{version}.dmg"
  name "clipboard-controller"
  desc "Menu bar clipboard history and clipboard cleaner"
  homepage "https://github.com/fballiano/clipboard-controller"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sequoia

  app "clipboard-controller.app"

  zap trash: [
    "~/Library/Application Support/clipboard-controller",
    "~/Library/Caches/com.fabrizioballiano.clipboard-controller",
    "~/Library/HTTPStorages/com.fabrizioballiano.clipboard-controller",
    "~/Library/Preferences/com.fabrizioballiano.clipboard-controller.plist",
  ]
end
