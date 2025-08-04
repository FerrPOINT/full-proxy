# Krea.ai Reverse Proxy

Профессиональный reverse-proxy для Krea.ai с использованием OpenResty/Lua, обеспечивающий прозрачное проксирование под собственным доменом `krea.acm-ai.ru`.

## 🎯 Цель проекта

Организовать прозрачное проксирование сайта Krea.ai под собственный домен с корректной подменой домена в:
- Куках (Set-Cookie заголовки)
- Заголовках HTTP
- Fetch/XHR-запросах
- localStorage
- Абсолютных URL в HTML/JS

## 🏗️ Архитектура

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐
│   Browser       │    │  OpenResty       │    │  Krea.ai    │
│                 │    │  Proxy           │    │             │
│ krea.acm-ai.ru  │───▶│  krea.acm-ai.ru  │───▶│  krea.ai    │
└─────────────────┘    └──────────────────┘    └─────────────┘
```

### Компоненты

- **OpenResty** - NGINX с встроенным Lua
- **Lua-фильтры** - для манипуляции заголовками и телом ответа
- **SSL/TLS** - Let's Encrypt сертификаты
- **CORS** - настройки для iframe поддержки

## 📋 Требования

- Ubuntu 18.04+ / CentOS 7+ / Debian 9+
- Root доступ
- Домен `krea.acm-ai.ru` настроенный на сервер
- Открытые порты 80 и 443

## 🚀 Быстрая установка

### 1. Клонирование репозитория

```bash
git clone <repository-url>
cd full-proxy
```

### 2. Установка OpenResty

```bash
chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

### 3. Настройка DNS

Настройте A-запись для домена `krea.acm-ai.ru` на IP вашего сервера.

### 4. Установка SSL сертификата

```bash
chmod +x scripts/manage.sh
sudo ./scripts/manage.sh ssl
```

### 5. Тестирование

```bash
chmod +x scripts/test.sh
./scripts/test.sh
```

## 📁 Структура проекта

```
full-proxy/
├── nginx.conf              # Основная конфигурация NGINX
├── lua/
│   ├── cookie_filter.lua   # Фильтр для Set-Cookie заголовков
│   └── body_filter.lua     # Фильтр для замены URL в теле ответа
├── scripts/
│   ├── install.sh          # Скрипт установки
│   ├── test.sh            # Скрипт тестирования
│   └── manage.sh          # Скрипт управления сервисом
├── info/
│   └── TZ.md              # Техническое задание
└── README.md              # Документация
```

## ⚙️ Конфигурация

### Основные настройки

Файл `nginx.conf` содержит:

- **SSL конфигурацию** с современными шифрами
- **CORS заголовки** для iframe поддержки
- **WebSocket поддержку** для real-time функциональности
- **Lua-фильтры** для манипуляции контентом
- **Безопасность** с CSP и X-Frame-Options

### Lua-фильтры

#### cookie_filter.lua
Перехватывает и модифицирует `Set-Cookie` заголовки:
- `Domain=krea.ai` → `Domain=krea.acm-ai.ru`
- `Domain=.krea.ai` → `Domain=krea.acm-ai.ru`
- Сохраняет все остальные флаги (Secure, SameSite, etc.)

#### body_filter.lua
Заменяет URL в теле ответа:
- `https://krea.ai` → `https://krea.acm-ai.ru`
- `//krea.ai` → `//krea.acm-ai.ru`
- JSON паттерны для API вызовов
- WebSocket URL

## 🧪 Тестирование

### Автоматические тесты

```bash
./scripts/test.sh
```

Тесты проверяют:
- ✅ Работу Lua
- ✅ SSL сертификат
- ✅ Подмену домена в куках
- ✅ Замену URL в контенте
- ✅ CORS заголовки
- ✅ Заголовки безопасности
- ✅ WebSocket поддержку
- ✅ Proxy заголовки

### Ручная проверка

1. **Откройте тестовую страницу:**
   ```
   https://krea.acm-ai.ru/krea-test.html
   ```

2. **Проверьте DevTools:**
   - Network tab: все запросы идут на `krea.acm-ai.ru`
   - Application → Cookies: домен `krea.acm-ai.ru`
   - Security: нет ошибок Mixed Content
   - Console: нет ошибок CSP

3. **Проверьте функциональность:**
   - Авторизация в iframe
   - Сохранение сессии
   - Генерация изображений
   - Переключение страниц

## 🔧 Управление сервисом

### Основные команды

```bash
# Запуск/остановка
sudo ./scripts/manage.sh start
sudo ./scripts/manage.sh stop
sudo ./scripts/manage.sh restart

# Перезагрузка конфигурации
sudo ./scripts/manage.sh reload

# Просмотр статуса и логов
sudo ./scripts/manage.sh status
sudo ./scripts/manage.sh logs

# Тестирование конфигурации
sudo ./scripts/manage.sh test

# Управление SSL
sudo ./scripts/manage.sh ssl

# Резервное копирование
sudo ./scripts/manage.sh backup
sudo ./scripts/manage.sh restore
```

### Логирование

Логи доступны в:
- `/var/log/nginx/access.log` - доступы
- `/var/log/nginx/error.log` - ошибки

Lua-логи включают:
- Перезапись кук
- Замену URL
- Ошибки фильтров

## 🔒 Безопасность

### Заголовки безопасности

- `X-Frame-Options: ALLOWALL` - разрешает iframe
- `Content-Security-Policy: frame-ancestors *` - CSP для iframe
- `Access-Control-Allow-Credentials: true` - CORS для iframe

### SSL/TLS

- Современные протоколы (TLS 1.2, 1.3)
- Сильные шифры
- Автоматическое обновление через Let's Encrypt

## 🐛 Устранение неполадок

### Частые проблемы

1. **Lua не работает**
   ```bash
   curl https://krea.acm-ai.ru/lua_test
   # Должно вернуть: "Lua работает!"
   ```

2. **SSL ошибки**
   ```bash
   sudo ./scripts/manage.sh ssl
   ```

3. **Конфигурация не загружается**
   ```bash
   sudo nginx -t
   sudo ./scripts/manage.sh reload
   ```

4. **Куки не перезаписываются**
   - Проверьте логи: `sudo tail -f /var/log/nginx/error.log`
   - Убедитесь, что Lua-файлы доступны

5. **URL не заменяются**
   - Проверьте Content-Type ответа
   - Убедитесь, что Accept-Encoding отключен

### Диагностика

```bash
# Проверка конфигурации
sudo nginx -t

# Просмотр логов в реальном времени
sudo tail -f /var/log/nginx/error.log

# Тест прокси
curl -I https://krea.acm-ai.ru/

# Проверка SSL
openssl s_client -servername krea.acm-ai.ru -connect krea.acm-ai.ru:443
```

## 📊 Мониторинг

### Метрики для отслеживания

- Количество запросов
- Время ответа
- Ошибки SSL
- Ошибки Lua-фильтров
- Использование памяти

### Настройка мониторинга

```bash
# Установка Prometheus Node Exporter
sudo apt-get install prometheus-node-exporter

# Настройка логирования в JSON
# Добавьте в nginx.conf:
# log_format json escape=json '{...}';
```

## 🔄 Обновления

### Обновление конфигурации

1. Создайте резервную копию:
   ```bash
   sudo ./scripts/manage.sh backup
   ```

2. Обновите файлы конфигурации

3. Протестируйте:
   ```bash
   sudo ./scripts/manage.sh test
   ```

4. Перезагрузите:
   ```bash
   sudo ./scripts/manage.sh reload
   ```

### Обновление OpenResty

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get upgrade openresty

# CentOS/RHEL
sudo yum update openresty
```

## 📝 Чек-лист развертывания

- [ ] DNS настроен: `krea.acm-ai.ru` → IP сервера
- [ ] OpenResty установлен и работает
- [ ] SSL сертификат установлен
- [ ] Lua-фильтры работают
- [ ] Тесты проходят успешно
- [ ] Тестовая страница загружается
- [ ] DevTools показывают корректные запросы
- [ ] Куки сохраняются с правильным доменом
- [ ] Нет ошибок Mixed Content
- [ ] Авторизация работает в iframe

## 🤝 Поддержка

### Логи и отладка

Для получения подробной информации о проблемах:

```bash
# Включить debug логирование
# Добавьте в nginx.conf:
# error_log /var/log/nginx/error.log debug;

# Перезагрузите конфигурацию
sudo ./scripts/manage.sh reload

# Просмотр логов
sudo tail -f /var/log/nginx/error.log
```

### Полезные команды

```bash
# Проверка статуса всех компонентов
sudo systemctl status openresty
sudo nginx -V  # Версия и модули
lua -v         # Версия Lua

# Тест производительности
ab -n 1000 -c 10 https://krea.acm-ai.ru/

# Мониторинг в реальном времени
htop
iotop
```

## 📄 Лицензия

Проект распространяется под лицензией MIT.

## ⚠️ Важные замечания

1. **Правовые аспекты**: Убедитесь, что использование прокси не нарушает Terms of Service Krea.ai
2. **Производительность**: Мониторьте нагрузку на сервер
3. **Безопасность**: Регулярно обновляйте OpenResty и SSL сертификаты
4. **Резервное копирование**: Регулярно создавайте резервные копии конфигурации

---

**Автор**: ACM AI Team  
**Версия**: 1.0.0  
**Дата**: 2024 