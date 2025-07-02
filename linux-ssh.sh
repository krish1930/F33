#!/bin/bash

# Usage: ./linux-run.sh LINUX_USER_PASSWORD NGROK_AUTH_TOKEN

LINUX_USER_PASSWORD="${1:-krish}"
NGROK_AUTH_TOKEN="${2:-2SKcLerzezlK6RqZ46Qn94kvKlW_5dyB5HGL386Pgx8JrAaZ8}"

if [[ -z "$LINUX_USER_PASSWORD" || -z "$NGROK_AUTH_TOKEN" ]]; then
  echo "Usage: $0 LINUX_USER_PASSWORD NGROK_AUTH_TOKEN"
  exit 1
fi

echo "### Installing ngrok ###"
wget -q -O ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
tar -xzf ngrok.tgz
chmod +x ngrok
rm ngrok.tgz

echo "### Configuring ngrok ###"
./ngrok authtoken "$NGROK_AUTH_TOKEN"

echo "### Installing gotty (web terminal) ###"
wget -q https://github.com/yudai/gotty/releases/download/v0.2.0/gotty_linux_amd64.tar.gz -O gotty.tar.gz
tar -xzf gotty.tar.gz
chmod +x gotty
rm gotty.tar.gz

echo "### Starting gotty web terminal on port 8080 ###"
./gotty -w bash &

sleep 5

echo "### Starting ngrok HTTP tunnel for port 8080 ###"
./ngrok http 8080 > .ngrok.log &

sleep 10

NGROK_URL=$(grep -o -m1 "https://[0-9a-zA-Z./]*\.ngrok.io" .ngrok.log)

if [[ -n "$NGROK_URL" ]]; then
  echo ""
  echo "=========================================="
  echo "🔓 Web shell available at: $NGROK_URL"
  echo "Username: (leave blank)"
  echo "Password: (leave blank unless configured)"
  echo "=========================================="
else
  echo "❌ Ngrok tunnel failed to start or no URL found."
  cat .ngrok.log
  exit 2
fi
