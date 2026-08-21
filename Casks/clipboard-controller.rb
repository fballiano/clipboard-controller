cask "clipboard-controller" do
  version "1.0.2"
  sha256 "a61ac1ddb1aba639b40c1e7d26338ab0d373a20ab50c8ae58e2fa1716c790ce6"

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
