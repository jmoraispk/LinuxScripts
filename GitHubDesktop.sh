# GitHubDesktop on Linux:
# From: https://gist.github.com/berkorbay/6feda478a00b0432d13f1fc0a50467f1

# get deb package
sudo wget https://github.com/shiftkey/desktop/releases/download/release-2.9.3-linux3/GitHubDesktop-linux-2.9.3-linux3.deb

# install package installer
sudo apt-get install -y gdebi-core

# install downloaded package
sudo gdebi GitHubDesktop-linux-2.9.3-linux3.deb

