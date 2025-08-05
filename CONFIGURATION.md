# 🔧 Конфигурация Krea.ai Proxy

## 📝 Файл config.env

### Обязательные настройки:

```bash
# Ваш домен для прокси (замените на ваш домен)
PROXY_DOMAIN=your-domain.com

# Email для SSL сертификатов Let's Encrypt (любой валидный email)
SSL_EMAIL=your-email@domain.com
```

### Опциональные настройки:

```bash
# Целевой сайт для проксирования (по умолчанию krea.ai)
TARGET_DOMAIN=krea.ai

# Автоматически определяется IP сервера
SERVER_IP=$(hostname -I | awk '{print $1}')
```

## 🎯 Что нужно изменить:

### 1. **PROXY_DOMAIN** (ОБЯЗАТЕЛЬНО)
```bash
# Замените на ваш домен
PROXY_DOMAIN=my-proxy-domain.com
```

### 2. **SSL_EMAIL** (ОБЯЗАТЕЛЬНО)
```bash
# Любой валидный email для SSL сертификатов
SSL_EMAIL=admin@my-domain.com
# или
SSL_EMAIL=webmaster@my-domain.com
# или даже
SSL_EMAIL=test@example.com
```

## ❓ Зачем нужен email?

Email используется **ТОЛЬКО** для:
- ✅ Уведомлений об истечении SSL сертификатов
- ✅ Восстановления доступа к SSL сертификатам
- ❌ НЕ используется для авторизации
- ❌ НЕ отправляется на этот email
- ❌ НЕ влияет на работу прокси

## 🚀 Примеры конфигурации:

### Пример 1: Прокси для krea.ai
```bash
PROXY_DOMAIN=my-krea-proxy.com
SSL_EMAIL=admin@my-krea-proxy.com
TARGET_DOMAIN=krea.ai
```

### Пример 2: Прокси для другого сайта
```bash
PROXY_DOMAIN=my-proxy.com
SSL_EMAIL=webmaster@my-proxy.com
TARGET_DOMAIN=target-site.com
```

### Пример 3: Минимальная настройка
```bash
PROXY_DOMAIN=proxy.example.com
SSL_EMAIL=any@email.com
# TARGET_DOMAIN=krea.ai (по умолчанию)
```

## ⚠️ Важно:

1. **Домен должен указывать на ваш сервер** в DNS
2. **Email должен быть валидным** (для Let's Encrypt)
3. **Остальные настройки можно оставить по умолчанию** 