# Инструкции по развертыванию Krea.ai Proxy

## 🚀 Быстрое развертывание

### Вариант 1: Docker (Рекомендуется)

```bash
# 1. Клонируйте репозиторий
git clone <repository-url>
cd full-proxy

# 2. Настройте DNS
# Укажите A-запись: krea.acm-ai.ru → IP вашего сервера

# 3. Запустите развертывание
chmod +x scripts/docker-deploy.sh
./scripts/docker-deploy.sh

# 4. Установите SSL сертификат
docker-compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/html \
  --email admin@acm-ai.ru --agree-tos --no-eff-email \
  -d krea.acm-ai.ru

# 5. Протестируйте
./scripts/test.sh
```

### Вариант 2: Нативная установка

```bash
# 1. Клонируйте репозиторий
git clone <repository-url>
cd full-proxy

# 2. Установите OpenResty
chmod +x scripts/install.sh
sudo ./scripts/install.sh

# 3. Настройте DNS
# Укажите A-запись: krea.acm-ai.ru → IP вашего сервера

# 4. Установите SSL сертификат
sudo ./scripts/manage.sh ssl

# 5. Протестируйте
./scripts/test.sh
```

## 📋 Предварительные требования

### Системные требования

- **ОС**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **RAM**: Минимум 512MB, рекомендуется 1GB+
- **CPU**: 1 ядро, рекомендуется 2+
- **Диск**: 10GB свободного места
- **Сеть**: Открытые порты 80 и 443

### Для Docker развертывания

- Docker 20.10+
- Docker Compose 2.0+

### Для нативной установки

- Root доступ
- Интернет соединение для загрузки пакетов

## 🔧 Подробная настройка

### 1. Подготовка сервера

```bash
# Обновление системы
sudo apt-get update && sudo apt-get upgrade -y

# Установка базовых инструментов
sudo apt-get install -y curl wget git

# Настройка firewall (если используется)
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 22
```

### 2. Настройка DNS

Настройте следующие записи в вашем DNS провайдере:

```
Type: A
Name: krea.acm-ai.ru
Value: [IP вашего сервера]
TTL: 300
```

### 3. Проверка DNS

```bash
# Проверьте, что DNS настроен правильно
nslookup krea.acm-ai.ru
dig krea.acm-ai.ru

# Должно вернуть IP вашего сервера
```

## 🐳 Docker развертывание

### Подготовка Docker

```bash
# Установка Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Установка Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Перезагрузка для применения изменений
newgrp docker
```

### Развертывание

```bash
# Клонирование и настройка
git clone <repository-url>
cd full-proxy

# Создание .env файла
cp .env.example .env
# Отредактируйте .env файл при необходимости

# Запуск
./scripts/docker-deploy.sh
```

### Управление контейнерами

```bash
# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down

# Перезапуск
docker-compose restart

# Обновление
docker-compose pull
docker-compose up -d

# Доступ к контейнеру
docker-compose exec krea-proxy sh
```

## 🔒 SSL сертификаты

### Автоматическая установка (Let's Encrypt)

```bash
# Для Docker
docker-compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/html \
  --email admin@acm-ai.ru --agree-tos --no-eff-email \
  -d krea.acm-ai.ru

# Для нативной установки
sudo ./scripts/manage.sh ssl
```

### Ручная установка

1. Получите сертификат от вашего провайдера
2. Разместите файлы в `/etc/letsencrypt/live/krea.acm-ai.ru/`
3. Обновите конфигурацию NGINX

### Автоматическое обновление

```bash
# Добавьте в crontab
sudo crontab -e

# Добавьте строку:
0 12 * * * /usr/bin/certbot renew --quiet
```

## 🧪 Тестирование

### Автоматические тесты

```bash
# Запуск всех тестов
./scripts/test.sh

# Отдельные тесты
curl -I https://krea.acm-ai.ru/lua_test
curl -I https://krea.acm-ai.ru/
```

### Ручная проверка

1. **Откройте браузер и перейдите на:**
   ```
   https://krea.acm-ai.ru/krea-test.html
   ```

2. **Проверьте DevTools:**
   - Network tab: все запросы на `krea.acm-ai.ru`
   - Application → Cookies: домен `krea.acm-ai.ru`
   - Security: нет ошибок Mixed Content

3. **Проверьте функциональность:**
   - Авторизация работает
   - Сессия сохраняется
   - Генерация изображений работает

## 🔧 Управление сервисом

### Основные команды

```bash
# Статус сервиса
sudo ./scripts/manage.sh status

# Просмотр логов
sudo ./scripts/manage.sh logs

# Перезагрузка конфигурации
sudo ./scripts/manage.sh reload

# Резервное копирование
sudo ./scripts/manage.sh backup

# Восстановление
sudo ./scripts/manage.sh restore
```

### Мониторинг

```bash
# Просмотр логов в реальном времени
sudo tail -f /var/log/nginx/error.log

# Проверка использования ресурсов
htop
df -h
free -h

# Проверка сетевых соединений
netstat -tulpn | grep :80
netstat -tulpn | grep :443
```

## 🐛 Устранение неполадок

### Частые проблемы

#### 1. Lua не работает
```bash
# Проверьте конфигурацию
sudo nginx -t

# Проверьте права доступа
ls -la /etc/nginx/lua/

# Проверьте логи
sudo tail -f /var/log/nginx/error.log
```

#### 2. SSL ошибки
```bash
# Проверьте сертификат
openssl s_client -servername krea.acm-ai.ru -connect krea.acm-ai.ru:443

# Переустановите сертификат
sudo ./scripts/manage.sh ssl
```

#### 3. Куки не перезаписываются
```bash
# Проверьте Lua-фильтр
curl -I https://krea.acm-ai.ru/ | grep -i set-cookie

# Проверьте логи
sudo tail -f /var/log/nginx/error.log | grep cookie
```

#### 4. URL не заменяются
```bash
# Проверьте Content-Type
curl -I https://krea.acm-ai.ru/ | grep content-type

# Проверьте Accept-Encoding
curl -I https://krea.acm-ai.ru/ | grep accept-encoding
```

### Диагностика

```bash
# Полная диагностика
./scripts/test.sh

# Проверка конфигурации
sudo nginx -t

# Проверка портов
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Проверка процессов
ps aux | grep nginx
ps aux | grep openresty
```

## 📊 Мониторинг и логирование

### Настройка логирования

```bash
# Просмотр логов доступа
sudo tail -f /var/log/nginx/access.log

# Просмотр логов ошибок
sudo tail -f /var/log/nginx/error.log

# Поиск ошибок
sudo grep -i error /var/log/nginx/error.log
```

### Метрики для мониторинга

- Количество запросов в секунду
- Время ответа
- Количество ошибок
- Использование памяти и CPU
- Статус SSL сертификатов

### Настройка алертов

```bash
# Пример скрипта для мониторинга
#!/bin/bash
if ! curl -f https://krea.acm-ai.ru/lua_test &>/dev/null; then
    echo "Proxy is down!" | mail -s "Proxy Alert" admin@acm-ai.ru
fi
```

## 🔄 Обновления

### Обновление конфигурации

```bash
# Создание резервной копии
sudo ./scripts/manage.sh backup

# Обновление файлов
git pull

# Тестирование
sudo ./scripts/manage.sh test

# Перезагрузка
sudo ./scripts/manage.sh reload
```

### Обновление OpenResty

```bash
# Для Ubuntu/Debian
sudo apt-get update
sudo apt-get upgrade openresty

# Для CentOS/RHEL
sudo yum update openresty

# Перезапуск
sudo systemctl restart openresty
```

## 📝 Чек-лист развертывания

- [ ] Сервер подготовлен (обновлен, настроен firewall)
- [ ] DNS настроен: `krea.acm-ai.ru` → IP сервера
- [ ] OpenResty установлен и работает
- [ ] Конфигурация NGINX корректна
- [ ] Lua-фильтры работают
- [ ] SSL сертификат установлен
- [ ] Автоматические тесты проходят
- [ ] Тестовая страница загружается
- [ ] DevTools показывают корректные запросы
- [ ] Куки сохраняются с правильным доменом
- [ ] Нет ошибок Mixed Content
- [ ] Авторизация работает в iframe
- [ ] Логирование настроено
- [ ] Резервное копирование настроено
- [ ] Мониторинг настроен

## 🆘 Поддержка

### Полезные команды

```bash
# Проверка статуса всех компонентов
sudo systemctl status openresty
sudo nginx -V
lua -v

# Тест производительности
ab -n 1000 -c 10 https://krea.acm-ai.ru/

# Проверка SSL
openssl s_client -servername krea.acm-ai.ru -connect krea.acm-ai.ru:443

# Проверка DNS
nslookup krea.acm-ai.ru
dig krea.acm-ai.ru
```

### Логи для отладки

```bash
# Включение debug логирования
# Добавьте в nginx.conf:
# error_log /var/log/nginx/error.log debug;

# Перезагрузите конфигурацию
sudo ./scripts/manage.sh reload

# Просмотр логов
sudo tail -f /var/log/nginx/error.log
```

---

**Версия документации**: 1.0.0  
**Последнее обновление**: 2024 