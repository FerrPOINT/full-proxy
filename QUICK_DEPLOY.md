# 🚀 Быстрое развертывание Krea.ai Proxy

## 📋 Ситуация: У вас уже есть NGINX + SSL сертификаты + другие сайты

### Что мы делаем:
1. **Исправляем все проблемы** с конфигурацией
2. **Устанавливаем Lua модуль** (если не установлен)
3. **Создаем резервную копию** существующей конфигурации
4. **Добавляем только конфигурацию для Krea.ai** как отдельный сайт
5. **Сохраняем все существующие сайты** без изменений
6. **Тестируем** функциональность

---

## ⚡ Исправление всех проблем (5 минут)

### Автоматический скрипт (Рекомендуется)

```bash
# Скачайте проект
git clone <repository-url>
cd full-proxy

# Запустите исправляющий скрипт
sudo ./scripts/fix-all.sh
```

### Ручная установка (если скрипт не работает)

```bash
# 1. Установите Lua модуль (если не установлен)
sudo apt-get update
sudo apt-get install -y libnginx-mod-http-lua

# 2. Создайте резервную копию
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

# 3. Скопируйте Lua-скрипты
sudo mkdir -p /etc/nginx/lua
sudo cp lua/cookie_filter.lua /etc/nginx/lua/
sudo cp lua/body_filter.lua /etc/nginx/lua/
sudo chmod 644 /etc/nginx/lua/*.lua

# 4. Создайте конфигурацию для Krea.ai
sudo cp scripts/krea-site.conf /etc/nginx/sites-available/krea.acm-ai.ru
sudo ln -sf /etc/nginx/sites-available/krea.acm-ai.ru /etc/nginx/sites-enabled/

# 5. Проверьте и перезагрузите
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🛡️ Что делает исправляющий скрипт

### ✅ Исправляет все проблемы:
- **Синтаксические ошибки** в конфигурации NGINX
- **Устанавливает Lua модуль** если отсутствует
- **Исправляет права доступа** к Lua скриптам
- **Создает правильную конфигурацию** Krea.ai
- **Размещает заголовки безопасности** в правильных местах
- **Настраивает CORS** для работы в iframe

### ✅ Сохраняет существующие настройки:
- **Резервная копия** конфигурации NGINX
- **Не перезаписывает** основной nginx.conf
- **Добавляет только** конфигурацию для krea.acm-ai.ru
- **Использует reload** вместо restart

### ✅ Создает отдельный сайт:
- **Файл**: `/etc/nginx/sites-available/krea.acm-ai.ru`
- **Симлинк**: `/etc/nginx/sites-enabled/krea.acm-ai.ru`
- **Не влияет** на другие сайты

### ✅ Проверяет безопасность:
- **Тестирует конфигурацию** перед применением
- **Проверяет статус** NGINX после reload
- **Создает backup** для отката

---

## 🧪 Тестирование функциональности

### 1. Базовые тесты

```bash
# Тест Lua
curl http://localhost/lua_test

# Тест SSL (если настроен)
curl -I https://krea.acm-ai.ru/

# Тест проксирования
curl -I https://krea.acm-ai.ru/ | grep -i "set-cookie"
```

### 2. Проверка в браузере

1. Откройте: `https://krea.acm-ai.ru/krea-test.html`
2. Проверьте DevTools → Network: все запросы на `krea.acm-ai.ru`
3. Проверьте DevTools → Application → Cookies: домен `krea.acm-ai.ru`
4. Проверьте DevTools → Security: нет ошибок Mixed Content

### 3. Проверка существующих сайтов

```bash
# Убедитесь, что другие сайты работают
sudo systemctl status nginx
# Должен показать "active (running)"

# Проверьте все сайты
sudo nginx -T | grep "server_name"
# Должен показать все ваши домены
```

---

## 🔧 Управление сервисом

```bash
# Перезагрузка конфигурации (безопасно)
sudo nginx -t && sudo systemctl reload nginx

# Просмотр логов
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Статус всех сайтов
sudo nginx -T | grep "server_name"
```

---

## 🐛 Частые проблемы

### 1. "nginx: [emerg] module not found"
```bash
# Установите Lua модуль
sudo apt-get install libnginx-mod-http-lua
sudo systemctl restart nginx
```

### 2. "SSL certificate not found"
```bash
# Проверьте пути к сертификатам
sudo ls -la /etc/letsencrypt/live/krea.acm-ai.ru/

# Обновите пути в конфигурации
sudo nano /etc/nginx/sites-available/krea.acm-ai.ru
```

### 3. "add_header directive is not allowed here"
```bash
# Запустите исправляющий скрипт
sudo ./scripts/fix-all.sh
```

### 4. Существующие сайты не работают
```bash
# Проверьте backup
sudo ls -la /etc/nginx/backup_*

# Восстановите конфигурацию
sudo cp /etc/nginx/nginx.conf.backup /etc/nginx/nginx.conf
sudo systemctl reload nginx
```

### 5. Конфликт портов
```bash
# Проверьте какие порты используются
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Убедитесь, что нет конфликтов доменов
```

---

## 📊 Проверка работоспособности

### Автоматический тест

```bash
# Запустите тест
./scripts/test.sh
```

### Ручная проверка

1. **Откройте**: `https://krea.acm-ai.ru/krea-test.html`
2. **Проверьте**: iframe загружается без ошибок
3. **Попробуйте**: авторизацию в iframe
4. **Убедитесь**: сессия сохраняется при переходах
5. **Проверьте**: другие сайты работают

---

## 🎯 Что получится

После установки:
- ✅ `https://krea.acm-ai.ru/` → проксирует `https://krea.ai`
- ✅ Все куки сохраняются с доменом `krea.acm-ai.ru`
- ✅ Все URL в контенте заменяются на `krea.acm-ai.ru`
- ✅ Работает в iframe без ошибок
- ✅ SSL сертификат валидный
- ✅ Авторизация и сессии работают
- ✅ **Все существующие сайты продолжают работать**

---

## 📝 Чек-лист

- [ ] Резервная копия создана
- [ ] Lua модуль установлен
- [ ] Lua-скрипты скопированы
- [ ] Конфигурация Krea.ai добавлена
- [ ] SSL сертификаты настроены
- [ ] DNS указывает на сервер
- [ ] NGINX перезагружен (не перезапущен)
- [ ] Lua тест работает
- [ ] Прокси отвечает
- [ ] Тестовая страница загружается
- [ ] **Существующие сайты работают**

**Готово! Все сайты в безопасности!** 🚀 