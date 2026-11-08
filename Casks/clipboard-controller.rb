cask "clipboard-controller" do
  version "1.2.1"
  sha256 "172150ad8d4987137811dd9b44162541ce22bc44eb9a74808f595c5b25a2f913"

  url "https://github.com/fballiano/clipboard-controller/releases/download/v#{version}/clipboard-controller-#{version}.dmg"
  name "clipboard-controller"
  desc "Menu bar clipboard history and clipboard cleaner"
  homepage "https://github.com/fballiano/clipboard-controller"

  livecheck do
    url :url
    strategy :github_latest
  end

  deprecate! date: "2026-11-08", because: "has moved to fballiano/tap/clipyard"

  depends_on macos: :sequoia

  app "clipboard-controller.app"

  zap trash: [
    "~/Library/Application Support/clipboard-controller",
    "~/Library/Caches/com.fabrizioballiano.clipboard-controller",
    "~/Library/HTTPStorages/com.fabrizioballiano.clipboard-controller",
    "~/Library/Preferences/com.fabrizioballiano.clipboard-controller.plist",
  ]
end
