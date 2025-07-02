#!/bin/bash

# Usage: ./linux-run.sh LINUX_USER_PASSWORD NGROK_AUTH_TOKEN LINUX_USERNAME LINUX_MACHINE_NAME

LINUX_USER_PASSWORD=krish
NGROK_AUTH_TOKEN=2SKcLerzezlK6RqZ46Qn94kvKlW_5dyB5HGL386Pgx8JrAaZ8
LINUX_USERNAME=krish
LINUX_MACHINE_NAME=krish

if [[ -z "$LINUX_USER_PASSWORD" || -z "$NGROK_AUTH_TOKEN" || -z "$LINUX_USERNAME" || -z "$LINUX_MACHINE_NAME" ]]; then
  echo "Usage: $0 LINUX_USER_PASSWORD NGROK_AUTH_TOKEN LINUX_USERNAME LINUX_MACHINE_NAME"
  exit 1
fi

echo "### Creating new user: $LINUX_USERNAME ###"
sudo useradd -m "$LINUX_USERNAME"
echo "$LINUX_USERNAME:$LINUX_USER_PASSWORD" | sudo chpasswd
sudo usermod -aG sudo "$LINUX_USERNAME"
sudo sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd
sudo hostnamectl set-hostname "$LINUX_MACHINE_NAME"

echo "### Installing ngrok ###"
wget -q -O ngrok.tgz https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz
sudo tar -xzf ngrok.tgz -C /usr/local/bin
rm -f ngrok.tgz
chmod +x /usr/local/bin/ngrok

echo "### Configuring ngrok ###"
/usr/local/bin/ngrok authtoken "$NGROK_AUTH_TOKEN"

echo "### Updating password for default user ($USER) ###"
echo "$USER:$LINUX_USER_PASSWORD" | sudo chpasswd

echo "### Starting ngrok tunnel for SSH (port 22) ###"
rm -f .ngrok.log
/usr/local/bin/ngrok tcp 22 --log ".ngrok.log" &

sleep 10

HAS_ERRORS=$(grep "command failed" .ngrok.log)

if [[ -z "$HAS_ERRORS" ]]; then
  NGROK_URL=$(grep -o -E "tcp://[0-9a-zA-Z.:]+" .ngrok.log)
  SSH_CMD=$(echo "$NGROK_URL" | sed "s/tcp:\/\//ssh $LINUX_USERNAME@/" | sed "s/:/ -p /")

  echo ""
  echo "=========================================="
  echo "To connect: $SSH_CMD"
  echo "=========================================="
else
  echo "Ngrok failed to start:"
  echo "$HAS_ERRORS"
  exit 4
fi
