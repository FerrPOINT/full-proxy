# 🚀 Krea.ai Reverse Proxy

Профессиональный прозрачный reverse-proxy для Krea.ai, маршрутизирующий трафик с `krea.acm-ai.ru` на `https://www.krea.ai`.

## ✨ Возможности

- ✅ **Прозрачное проксирование** - пользователи воспринимают как "нативное" приложение
- ✅ **SSL/TLS поддержка** - автоматическая установка Let's Encrypt сертификатов
- ✅ **Перезапись доменов** - куки, заголовки, fetch/XHR, localStorage
- ✅ **WebSocket поддержка** - для real-time функциональности
- ✅ **CORS настройки** - для работы в iframe
- ✅ **Безопасность** - rate limiting, security headers
- ✅ **Безопасный деплой** - не нарушает существующие сайты

## 🛠️ Быстрый старт

### Для серверов с существующим NGINX

```bash
# 1. Клонировать репозиторий
git clone https://github.com/FerrPOINT/full-proxy.git
cd full-proxy

# 2. Настроить домены в config.env
nano config.env

# 3. Запустить безопасный деплой
sudo bash scripts/safe-deploy.sh
```

### Конфигурация (config.env)

```bash
# Домены
TARGET_DOMAIN=www.krea.ai
PROXY_DOMAIN=krea.acm-ai.ru

# SSL сертификаты
SSL_EMAIL=your-email@domain.com
```

## 📁 Структура проекта

```
full-proxy/
├── config.env              # Конфигурация доменов
├── scripts/
│   ├── safe-deploy.sh     # Основной скрипт деплоя
│   └── test.sh            # Тестирование функциональности
├── lua/
│   ├── cookie_filter.lua  # Перезапись куки и заголовков
│   └── body_filter.lua    # Замена URL в контенте
├── info/
│   ├── TZ.md             # Техническое задание
│   └── QUICK_DEPLOY.md   # Быстрая инструкция деплоя
└── QUICK_DEPLOY.md       # Быстрая инструкция (корневая)
```

## 🔧 Технологии

- **NGINX** - основной reverse proxy
- **OpenResty** - NGINX с Lua модулем
- **Lua** - динамическая обработка заголовков и контента
- **Let's Encrypt** - автоматические SSL сертификаты

## 🧪 Тестирование

```bash
# Тест Lua
curl https://krea.acm-ai.ru/lua_test

# Тестовая страница
curl https://krea.acm-ai.ru/krea-test.html

# Основной прокси
curl https://krea.acm-ai.ru/

# Полный тест
./scripts/test.sh
```

## 📋 Что обрабатывается

- **Set-Cookie заголовки** - перезапись домена
- **Location заголовки** - обработка редиректов
- **URL в HTML/JS/TS** - замена доменов
- **JSON/XML контент** - обновление ссылок
- **WebSocket соединения** - проксирование

## 🛡️ Безопасность

- Rate limiting (1000 req/s для Krea.ai)
- Security headers (HSTS, CSP, XSS Protection)
- CORS настройки для iframe
- SSL/TLS с современными протоколами

## 📚 Документация

- [QUICK_DEPLOY.md](QUICK_DEPLOY.md) - Быстрая инструкция деплоя
- [info/QUICK_DEPLOY.md](info/QUICK_DEPLOY.md) - Детальная инструкция в info
- [info/TZ.md](info/TZ.md) - Техническое задание

## 🚀 Готово к продакшену!

После установки:
- `https://krea.acm-ai.ru/` → проксирует `https://www.krea.ai`
- Все куки сохраняются с доменом `krea.acm-ai.ru`
- Все URL в контенте заменяются на `krea.acm-ai.ru`
- Работает в iframe без ошибок
- Авторизация и сессии работают корректно
- **Все существующие сайты продолжают работать**

---

**Профессиональное решение для прозрачного проксирования Krea.ai!** 🎯 