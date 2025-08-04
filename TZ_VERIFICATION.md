# ✅ Проверка соответствия ТЗ

## 🎯 Что мы делаем

Полностью проксируем Krea.ai под доменом `krea.acm-ai.ru` с:
- ✅ Подменой домена в куках
- ✅ Заменой URL в контенте  
- ✅ Работой в iframe
- ✅ Сохранением сессий

## 📋 Быстрая проверка ТЗ

### 1. Настройка сервера `krea.acm-ai.ru` для SSL ✅
```bash
# Проверка SSL
curl -I https://krea.acm-ai.ru/
# Должен вернуть 200 OK с SSL сертификатом
```

### 2. Проксирование ✅
```bash
# Проверка проксирования
curl -I https://krea.acm-ai.ru/ | grep -i "server"
# Должен показать, что запрос идет через прокси
```

### 3. Перехват и подмена `Set-Cookie` ✅
```bash
# Проверка кук
curl -I https://krea.acm-ai.ru/ | grep -i "set-cookie"
# Должен показать Domain=krea.acm-ai.ru
```

### 4. Подмена URL ✅
```bash
# Проверка замены URL
curl -s https://krea.acm-ai.ru/ | grep -o "krea.acm-ai.ru" | head -1
# Должен найти замененные URL
```

### 5. Настройка заголовков безопасности ✅
```bash
# Проверка заголовков
curl -I https://krea.acm-ai.ru/ | grep -E "(X-Frame-Options|Content-Security-Policy)"
# Должны присутствовать заголовки для iframe
```

### 6. Тестовый файл `/krea-test.html` ✅
```bash
# Проверка тестовой страницы
curl -s https://krea.acm-ai.ru/krea-test.html | grep -i "iframe"
# Должен найти iframe с src="https://krea.acm-ai.ru/"
```

### 7. Логирование ✅
```bash
# Проверка логов
sudo tail -n 5 /var/log/nginx/error.log
sudo tail -n 5 /var/log/nginx/access.log
# Должны быть логи запросов
```

### 8. Документация ✅
- ✅ `QUICK_DEPLOY.md` - краткая инструкция
- ✅ `scripts/quick-deploy.sh` - автоматический скрипт
- ✅ Все файлы конфигурации готовы

## 🚀 Быстрое развертывание

### Вариант 1: Автоматический скрипт
```bash
# Скачайте проект
git clone <repository-url>
cd full-proxy

# Запустите быстрый деплой
sudo ./scripts/quick-deploy.sh
```

### Вариант 2: Ручная установка
```bash
# 1. Установите OpenResty
sudo apt-get install openresty

# 2. Скопируйте файлы
sudo cp nginx.conf /etc/nginx/nginx.conf
sudo cp lua/*.lua /etc/nginx/lua/

# 3. Настройте SSL (если нужно)
sudo certbot --nginx -d krea.acm-ai.ru

# 4. Перезапустите
sudo systemctl restart openresty
```

## 🧪 Тестирование

### Автоматический тест
```bash
# Запустите все тесты
./scripts/test.sh
```

### Ручная проверка
1. Откройте: `https://krea.acm-ai.ru/krea-test.html`
2. Проверьте DevTools → Network: все запросы на `krea.acm-ai.ru`
3. Проверьте DevTools → Cookies: домен `krea.acm-ai.ru`
4. Попробуйте авторизацию в iframe

## 🎯 Результат

После установки:
- ✅ `https://krea.acm-ai.ru/` → проксирует `https://krea.ai`
- ✅ Все куки с доменом `krea.acm-ai.ru`
- ✅ Все URL заменены на `krea.acm-ai.ru`
- ✅ Работает в iframe без ошибок
- ✅ Авторизация и сессии работают

**Все требования ТЗ выполнены!** 🚀 