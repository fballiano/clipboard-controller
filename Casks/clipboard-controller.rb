cask "clipboard-controller" do
  version "1.0.0"
  sha256 "9e42deda7fc8472629d12afc195597bc22ee6d28828c7908395b4e8d78bf15c6"

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
