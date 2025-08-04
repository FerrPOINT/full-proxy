## 📄 Техническое задание: Реализация профессионального reverse‑proxy с OpenResty/Lua для Krea.ai

---

### 🎯 Цель

Организовать прозрачное проксирование сайта Krea.ai под собственный домен `krea.acm‑ai.ru`, с корректной подменой домена в куках, заголовках, fetch/XHR‑запросах и localStorage. Пользователи должны видеть инструмент как «родной», без разрывов сессии и логики, использующей origin браузера.

---

### ⚙️ Инструменты и стэк

* **OpenResty** (NGINX + ngx\_http\_lua\_module)
  Позволяет обрабатывать HTTP-заголовки и тело ответа через Lua и эффективно безопасно проксировать трафик. ([Ruby-Forum][1], [GitHub][2])

* **Модуль `lua-resty-cookie`**
  Для контроля и переписи `Set-Cookie` заголовков — раздел `Domain`, `Path`, `Flags`. ([groups.google.com][3])

* **Директива `proxy_cookie_domain` (NGINX)**
  Базовая подмена домена в заголовках куки. Оставлена как fallback (с регулярками). ([nginx.org][4])

* **Директива `body_filter_by_lua_block` + `sub_filter`**
  Реализует подмену всех абсолютных ссылок `https://krea.ai` → `https://krea.acm‑ai.ru`; и локальных доменов без протокола. ([Stack Overflow][5])

---

### 🛠 Задачи

1. **Настроить сервер `krea.acm‑ai.ru` для SSL** (Let’s Encrypt).
2. **Проксирование**:

   * Все HTTP/HTTPS-запросы (`/`) → `https://krea.ai$request_uri`.
   * Обработать работу с WebSocket, CORS, `OPTIONS`.
3. **Перехват и подмена `Set-Cookie`**:

   * `header_filter_by_lua_block`: переписать `Domain=.krea.ai` и `Domain=krea.ai` → `Domain=krea.acm‑ai.ru`, оставить все остальные flags — `Secure`, `SameSite=None`. ([docs.nginx.com][6], [Ruby-Forum][1])
   * Обработать ситуации, когда заголовков много (`ngx.header["Set-Cookie"]` — table или string).
4. **Подмена URL**:

   * `body_filter_by_lua_block`: заменить все `https://krea.ai`, `https://www.krea.ai`, `php.krea.ai` и bare `krea.ai`, `www.krea.ai` на `krea.acm‑ai.ru` в HTML/JS.
   * Удаление заголовка `Content-Length`, чтобы Lua-манипуляция не ломала поток. ([groups.google.com][3], [Stack Overflow][7])
   * Отключение `Accept-Encoding`, чтобы sub\_filter сработал для сжатого контента. ([Reddit][8])
5. **Настройка заголовков безопасности**:

   * `X-Frame-Options: ALLOWALL`
   * `Content-Security-Policy: frame-ancestors *`
   * `Access-Control-Allow-Credentials: true`, `Allow-Methods`, `Allow-Headers` — чтобы iframe и fetch внутри него считались same-origin.
6. **Тестовый файл `/krea-test.html`**:

   * С iframe `<iframe src="https://krea.acm‑ai.ru/" allow="...">`, без скриптов в нём, только для первого входа.
7. **Логирование**:

   * `access_log`, `error_log` в отдельные файлы.
   * Включить логирование `Set-Cookie`, через `lua` (например, `ngx.log(ngx.ERR, cookies)`).
8. **Документация**:

   * Инструкция по установке OpenResty, валидации Lua-модуля.
   * Скрипт проверки (`nginx -t && nginx reload`).
   * Документация по очистке куки и кеша и по пошаговой проверке.
   * Контрольный чек-лист (см. ниже).

---

### ✅ Критерии приёмки

* [ ] На `https://krea.acm‑ai.ru/krea-test.html` появляется проксированная страница Krea.ai.
* [ ] DevTools → **Security** → TLS соединение валидное, нет ошибок Mixed Content.
* [ ] DevTools → **Application → Cookies** — есть `Domain=krea.acm‑ai.ru` cookie (`session`, `flags`, если доступны).
* [ ] При авторизации в iframe после логина сессия сохраняется, переключение страниц, генерация изображений — сессия сохраняется.
* [ ] Все запросы в Network уходят на `krea.acm‑ai.ru`, нет запросов на `krea.ai`.
* [ ] Любой `Set-Cookie` от `krea.ai` Log содержит `Domain=krea.acm‑ai.ru`.
* [ ] Нет ошибок CSP / X-Frame-Options / X-Content-Type (в вкладках DevTools).
* [ ] Проверка автоматизации — сценарий:

  ```
  curl -I https://krea.acm-ai.ru
  ```

  возвращает заголовок вида `Set-Cookie: session=xxx; Domain=krea.acm-ai.ru; Secure; SameSite=None`

---

### 📆 План работ

| Этап | Задача                                                 | Ответственный | Срок    |
| ---- | ------------------------------------------------------ | ------------- | ------- |
| 1.   | Установка OpenResty с модулем Lua                      | DevOps        | 1 день  |
| 2.   | Написание конфигурации (включая proxy\_pass и фильтры) | Dev           | 1 день  |
| 3.   | Написание Lua-фильтра для подмены Set-Cookie           | Dev           | 1 день  |
| 4.   | Тестирование curl / DevTools / HAR                     | Dev + QA      | 1 день  |
| 5.   | Финальный аудит, документация, инструкции по деплою    | Dev           | 0.5 дня |

---

### 💬 Ограничения и предпосылки

* **Статичный SPA Krea.ai с минимальной логикой включения fetch по абсолютному коду** → работает.
* Если внутри сборки код динамически формирует абсолютные URL, подмена может не сработать — нужно ручное вмешательство.
* **Любые изменения на стороне Krea.ai** (обновление bundle, path, домена) потребуют проверки и возможной коррекции sub\_filter и Lua-кода.
* Использование такого прокси может быть против \[правил использования Krea.ai] — убедитесь, что это допустимо, иначе возможно нарушение политики (Terms of Service).

---

### 🧾 Чек-лист перед деплоем

* [ ] DNS/hosts `krea.acm‑ai.ru` → IP прокси
* [ ] SSL сертификат выпущен и проксирование работает
* [ ] `lua_test` location возвращает «Lua работает!»
* [ ] `Set-Cookie` domain подменяется
* [ ] sub\_filter заменяет все `krea.ai`
* [ ] Network в DevTools → все req идут на `krea.acm‑ai.ru`
* [ ] localStorage рабочий, самостоятельно сохраняется и используется
* [ ] fetch/ajax в iframe работают, заголовки `Origin: krea.acm‑ai.ru`

---

Это максимально профессиональное и “без лишних костылей” ТЗ для реализации решения через открытую платформу **OpenResty + Lua**.
Когда будешь готов — могу подготовить минимальный Lua-файл (`*.lua`), пример `nginx.conf`, и даже свои скрипты для CI/CD в связке с Certbot.

[1]: https://www.ruby-forum.com/t/rewriting-the-domain-part-of-set-cookie-in-a-proxy-pass/208025?utm_source=chatgpt.com "Rewriting the domain part of Set-Cookie in a proxy_pass"
[2]: https://github.com/openresty/lua-nginx-module?utm_source=chatgpt.com "openresty/lua-nginx-module: Embed the Power of Lua into ..."
[3]: https://groups.google.com/g/openresty-en/c/bvSGNSCP7tI?utm_source=chatgpt.com "Nginx Lua set-cookie header overwriting / removing any ..."
[4]: https://nginx.org/en/docs/http/ngx_http_proxy_module.html?utm_source=chatgpt.com "Module ngx_http_proxy_module"
[5]: https://stackoverflow.com/questions/72710633/fixing-nginx-sub-filter?utm_source=chatgpt.com "Fixing nginx sub_filter?"
[6]: https://docs.nginx.com/nginx/admin-guide/web-server/web-server/?utm_source=chatgpt.com "Configuring NGINX and NGINX Plus as a Web Server"
[7]: https://stackoverflow.com/questions/45356766/how-to-change-content-length-in-body-filter-by-lua-in-openresty?utm_source=chatgpt.com "How to change Content-length in body_filter_by_lua* in ..."
[8]: https://www.reddit.com/r/nginx/comments/j13wfk/proxy_pass_sub_filter_and_contentencoding_deflate/?utm_source=chatgpt.com "proxy_pass, sub_filter and \"Content-Encoding: deflate\""
