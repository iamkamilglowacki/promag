#!/bin/bash

# Dodaj klucz SSH do serwera

echo "🔑 Dodawanie klucza SSH do serwera..."
echo ""

SERVER_USER="u923457281"
SERVER_IP="46.17.175.219"
SERVER_PORT="65002"

# Klucz publiczny
SSH_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcSXVe6WdSMniady8dztgJjHZSl5JI4PFvtHJYue/gEmme8jtuVARC+plqsAWrprFBjnUGUddti+tFVzz3EC9xhVTAmr8GMOnUMeJjgtodAXNfvdecH47SNGt2FMx7zpYlWMgqVTZz+H3VIWWVEm9aB66NNI6J3pawkdQNtT6nuCfrRSbDoqZdE4CJH0iJklxjA4ZZJ4debOYCzDU6ts9PAkA11fZk+NXgn3kvoU6uHpLs6VYyfd+93dAs7RE+iUHnrIVrWIVa6g+Zbmq25KtO/VWklPPtCljhRO72iPX2BJMZHzKszfJymRFSly+uxnPubWgBW3ulrbJFl/JYBYwFgcsM1hX158/c+urAA8tkcW7d2Cuv592Nw1NJie4LvDz7ZZ2JjT2LSrPXwf8UImSrz3fCzgehpCeRfU8GzRQX95yiANz33dQlM66upSiw3p7oTxFEn8lZ4HAeU7Gv09qTMXtovy/7yps3CmZE4Nv7mdQyR1NvKQYR6V2QBGAp0HwfRyf2dD3gAGx+MaEeZKHk9iLUAHUBdDnIVZxeoinv0D/mT26DLBA6rNzaSzUGczpg2vmQQpc+xDSMgvKoZ8pzAkCIX2h4v8Xr6Rs+ZIIqNwT5XuHAoUOdCtHrU8EVypH5qr03Kra7lI2w3VYRlXIBKkNn8Mdl1lLNDkW0WmOTnQ== kamilglowacki@MacBook-Air-Kamil.local"

echo "To będzie wymagało hasła SSH (tylko raz!)"
echo ""

# Dodaj klucz do authorized_keys
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP << EOF
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "$SSH_KEY" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
echo "✅ Klucz dodany!"
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Klucz SSH został dodany!"
    echo ""
    echo "🧪 Testowanie połączenia bez hasła..."
    ssh -p $SERVER_PORT $SERVER_USER@$SERVER_IP "echo '✅ Połączenie działa bez hasła!'"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 SUKCES! Teraz możesz wdrażać bez hasła!"
        echo ""
        echo "Uruchom: ./quick_deploy.sh"
    fi
else
    echo "❌ Błąd podczas dodawania klucza"
fi
