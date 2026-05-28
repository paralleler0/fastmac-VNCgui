#!/bin/bash
# Usage: ./configure.sh VNC_USER_PASSWORD VNC_PASSWORD NGROK_AUTH_TOKEN

set -e

VNC_USER="vncuser"

sudo mdutil -i off -a || true

NEXT_UID=$(dscl . -list /Users UniqueID | awk '{print $2}' | sort -n | tail -1)
NEXT_UID=$((NEXT_UID + 1))

sudo dscl . -create /Users/$VNC_USER
sudo dscl . -create /Users/$VNC_USER UserShell /bin/bash
sudo dscl . -create /Users/$VNC_USER RealName "VNC User"
sudo dscl . -create /Users/$VNC_USER UniqueID "$NEXT_UID"
sudo dscl . -create /Users/$VNC_USER PrimaryGroupID 20
sudo dscl . -create /Users/$VNC_USER NFSHomeDirectory /Users/$VNC_USER

echo "$1" | sudo dscl . -passwd /Users/$VNC_USER
sudo createhomedir -c -u $VNC_USER > /dev/null

VNC_PATH="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart"

sudo "$VNC_PATH" -configure -allowAccessFor -specifiedUsers
sudo "$VNC_PATH" -configure -users $VNC_USER
sudo "$VNC_PATH" -configure -clientopts -setvnclegacy -vnclegacy yes

VNC_PASS_SHORT="${2:0:8}"

echo "$VNC_PASS_SHORT" | perl -we '
BEGIN {
  @k = unpack("C*", pack("H*", "1734516E8BA8C5E2FF1C39567390ADCA"));
}
$_ = <STDIN>;
chomp;
s/^(.{8}).*/$1/;
@p = unpack("C*", $_);
foreach (@k) {
  printf "%02X", $_ ^ (shift @p || 0);
}
print "\n";
' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt > /dev/null

sudo "$VNC_PATH" -restart -agent -console
sudo "$VNC_PATH" -activate

ARCH=$(uname -m)

if [ "$ARCH" = "arm64" ]; then
  URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.zip"
else
  URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.zip"
fi

curl -L "$URL" -o ngrok.zip

file ngrok.zip

unzip -o ngrok.zip

chmod +x ngrok
sudo mv ngrok /usr/local/bin/ngrok

rm ngrok.zip

ngrok config add-authtoken "$3"

/usr/local/bin/ngrok tcp 5900 --log=stdout > ngrok.log &
