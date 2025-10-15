# Konfiguracja klucza SSH (bez hasła)

## Krok 1: Wygeneruj klucz SSH (jeśli nie masz)

```bash
ssh-keygen -t rsa -b 4096 -C "twoj@email.com"
```

Naciśnij Enter 3 razy (bez hasła)

## Krok 2: Skopiuj klucz publiczny

```bash
cat ~/.ssh/id_rsa.pub
```

Skopiuj cały output (zaczyna się od `ssh-rsa`)

## Krok 3: Dodaj klucz w panelu Hostinger

1. Panel Hostinger → SSH access
2. Kliknij "Add SSH key"
3. Wklej skopiowany klucz
4. Zapisz

## Krok 4: Przetestuj połączenie

```bash
ssh -p 65002 u923457281@46.17.175.219
```

Powinno połączyć BEZ pytania o hasło!

## Krok 5: Uruchom wdrożenie

```bash
./quick_deploy.sh
```

Teraz zadziała bez pytania o hasło!
