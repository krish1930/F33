#!/bin/bash

LINUX_USER_PASSWORD="krish"
NGROK_AUTH_TOKEN="2SKcLerzezlK6RqZ46Qn94kvKlW_5dyB5HGL386Pgx8JrAaZ8"

echo "### Installing ngrok ###"
wget -q -O ngrok.zip https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
unzip -o ngrok.zip
sudo mv ngrok /usr/local/bin/ngrok
chmod +x /usr/local/bin/ngrok
rm -f ngrok.zip

echo "### Configuring ngrok ###"
/usr/local/bin/ngrok config add-authtoken "$NGROK_AUTH_TOKEN"

echo "### Installing gotty (web terminal) ###"
wget -q https://github.com/yudai/gotty/releases/download/v0.0.11/gotty_linux_amd64 -O gotty
chmod +x gotty

echo "### Updating password for default user (runner) ###"
echo "runner:$LINUX_USER_PASSWORD" | sudo chpasswd

echo "### Starting gotty web terminal on port 8080 ###"
./gotty -w -p 8080 bash &
sleep 5

echo "### Starting ngrok HTTP tunnel for port 8080 ###"
/usr/local/bin/ngrok http --region=us 8080 > ngrok.log &
sleep 15

# Use ngrok's API to get public URL
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -oE 'https://[0-9a-z]+\.ngrok.io' | head -n 1)

if [[ -z "$NGROK_URL" ]]; then
  echo "❌ Ngrok tunnel failed to start or no URL found."
  exit 2
fi

echo ""
echo "=========================================="
echo "🔓 Web shell available at: $NGROK_URL"
echo "Login with user: runner"
echo "Password: $LINUX_USER_PASSWORD"
echo "=========================================="
