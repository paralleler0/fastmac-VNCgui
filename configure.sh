#!/bin/bash
# Usage: ./configure.sh VNC_USER_PASSWORD VNC_PASSWORD NGROK_AUTH_TOKEN

# 1. Disable spotlight
sudo mdutil -i off -a

# 2. Create new account 
cd /tmp
sudo dscl . -create /Users/vncuser
sudo dscl . -create /Users/vncuser UserShell /bin/bash
sudo dscl . -create /Users/vncuser RealName "VNC User"
sudo dscl . -create /Users/vncuser UniqueID 1001
sudo dscl . -create /Users/vncuser PrimaryGroupID 80
sudo dscl . -create /Users/vncuser NFSHomeDirectory /Users/vncuser
echo "$1" | sudo dscl . -passwd /Users/vncuser
sudo dseditgroup -o edit -a vncuser -t user admin
sudo createhomedir -c -u vncuser > /dev/null

# 3. Enable VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -allowAccessFor -allUsers -privs -all
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -configure -clientopts -setvnclegacy -vnclegacy yes

# 4. Set VNC password
echo "$2" | perl -we 'BEGIN { @k = unpack "C*", pack "H*", "1734516E8BA8C5E2FF1C39567390ADCA"}; $_ = <>; chomp; s/^(.{8}).*/$1/; @p = unpack "C*", $_; foreach (@k) { printf "%02X", $_ ^ (shift @p || 0) }; print "\n"' | sudo tee /Library/Preferences/com.apple.VNCSettings.txt > /dev/null

# 5. Start VNC
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -restart -agent -console
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate

# 6. Install Ngrok 
curl -Lk https://bin.equinox.io/c/b34236/ngrok-v3-stable-darwin-arm64.zip -o ngrok.zip
unzip -o ngrok.zip
chmod +x ./ngrok
sudo mv ./ngrok /usr/local/bin/ngrok
rm ngrok.zip

# 7. Configure and Start
/usr/local/bin/ngrok authtoken "$3"
/usr/local/bin/ngrok tcp 5900 --log=stdout &
