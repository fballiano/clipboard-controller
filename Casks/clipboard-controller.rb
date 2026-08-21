cask "clipboard-controller" do
  version "1.1.0"
  sha256 "40e32e895cd46f2b09403d6ab2cc90e00ba2cf69970db2fed86df9c04a2fc15c"

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
