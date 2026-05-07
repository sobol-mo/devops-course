# Тема 10: Дисципліна експлуатації — моніторинг та контроль стабільності — Лабораторна робота (FIXED)

> **Виправлена версія.** Адаптовано під реальне середовище: WSL Ubuntu, `ssh devvm-vagrant`, `ANSIBLE_CONFIG`, структура `devops-ai-assistant/training-project/`.

---

## 🎯 Мета роботи

Перетворити принципи моніторингу на мінімальну практичну систему контролю стабільності для `training-project`:

- написати bash-скрипт watchdog для перевірки `/health` endpoint
- навчити його вести лог результатів перевірок
- реалізувати alert при 3 невдачах поспіль
- запустити скрипт через `cron` на VM для автоматичної перевірки кожну хвилину
- додати Docker HEALTHCHECK до `docker-compose.yml`
- навчитись читати логи `journalctl` та `docker logs` під час діагностики
- написати runbook для типових операційних ситуацій

**Контекст:** Після Теми 9 ми маємо повний CI/CD цикл. Тепер замикаємо DevOps-петлю: `Деплой → Моніторинг → Feedback → Покращення`.

---

## 📁 Структура файлів, які ми створимо

```
devops-ai-assistant/
└── training-project/
    ├── monitoring/
    │   ├── healthcheck.sh       ← watchdog-скрипт
    │   └── runbook.md           ← операційна пам'ять команди
    ├── docker-compose.yml       ← додамо HEALTHCHECK
    └── ansible/
        └── playbook.yml         ← додамо задачу розгортання watchdog
```

---

## 🛠 Покрокова інструкція

### Крок 1: Перевірка передумов

Переконайся, що VM запущена і Flask-сервіс активний.

На **хості (Git Bash)**, з директорії де лежить `Vagrantfile`:

```bash
cd ~/Desktop/\!KHPI/DevOps/AI_ASSISTANT/devops-ai-assistant/10_Implementation/01_vm

# Перевіряємо статус VM
vagrant status
# Очікуваний результат: devops-sandbox running
```

Якщо VM не запущена:
```bash
vagrant up
```

Перевіряємо сервіс та базу:

```bash
ssh devvm-vagrant "sudo systemctl is-active training-app"
# Очікуваний результат: active

ssh devvm-vagrant "curl -s http://localhost:5000/health"
# Очікуваний результат: {"status":"ok"}

ssh devvm-vagrant "sudo bash -c 'cd /opt/training-app && docker compose ps'"
# Очікуваний результат: training-app-db-1 Up (healthy або Up)
```

Якщо щось не активне — запусти playbook з Теми 8:

```bash
wsl -d Ubuntu -- bash -c "cd /mnt/c/Users/chapa/Desktop/'!KHPI'/DevOps/AI_ASSISTANT/devops-ai-assistant/training-project/ansible && ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory.ini playbook.yml -e 'db_password=Training2024'"
```

---

### Крок 2: Створення watchdog-скрипту

На **хості**, у директорії `training-project/`:

```bash
cd ~/Desktop/\!KHPI/DevOps/AI_ASSISTANT/devops-ai-assistant/training-project
mkdir -p monitoring
```

Створи файл `monitoring/healthcheck.sh`:

```bash
cat > monitoring/healthcheck.sh << 'EOF'
#!/bin/bash
# Watchdog для training-app: перевіряє /health кожну хвилину
# Записує результат у лог і надсилає alert після 3 помилок поспіль

HEALTH_URL="http://127.0.0.1:5000/health"
LOG_FILE="/var/log/training-app/healthcheck.log"
ALERT_FILE="/var/log/training-app/alerts.log"
FAIL_COUNT_FILE="/tmp/training_healthcheck_fails"
MAX_FAILS=3

# Створюємо директорію для логів якщо не існує
mkdir -p /var/log/training-app

# Поточний час
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Поточна кількість помилок поспіль
FAILS=0
if [ -f "$FAIL_COUNT_FILE" ]; then
    FAILS=$(cat "$FAIL_COUNT_FILE")
fi

# Виконуємо перевірку (timeout 5 секунд)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$HEALTH_URL")

if [ "$HTTP_STATUS" = "200" ]; then
    # Успіх: записуємо OK, скидаємо лічильник помилок
    echo "$TIMESTAMP OK /health returned HTTP 200" >> "$LOG_FILE"
    echo "0" > "$FAIL_COUNT_FILE"
else
    # Помилка: збільшуємо лічильник
    FAILS=$((FAILS + 1))
    echo "$FAILS" > "$FAIL_COUNT_FILE"

    echo "$TIMESTAMP ERROR /health returned HTTP ${HTTP_STATUS} (fail $FAILS/$MAX_FAILS)" >> "$LOG_FILE"

    # Alert після MAX_FAILS помилок поспіль
    if [ "$FAILS" -ge "$MAX_FAILS" ]; then
        ALERT_MSG="$TIMESTAMP ALERT training-app healthcheck failed $FAILS times in a row. URL: $HEALTH_URL Last status: HTTP $HTTP_STATUS. Check: journalctl -u training-app"
        echo "$ALERT_MSG" >> "$ALERT_FILE"
        echo "$ALERT_MSG"  # також виводимо в stdout (для cron email)
    fi
fi
EOF
```

Перевір вміст файлу:

```bash
cat monitoring/healthcheck.sh
```

---

### Крок 3: Оновлення docker-compose.yml — Docker HEALTHCHECK

Відкрий `training-project/docker-compose.yml` і оновіть секцію `db`, додавши блок `healthcheck`:

```yaml
services:
  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: training_db
      POSTGRES_USER: training_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U training_user -d training_db"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s

volumes:
  postgres_data:
```

> 💡 `pg_isready` — це вбудована утиліта PostgreSQL, яка перевіряє готовність бази до прийому з'єднань. Після цього `docker compose ps` буде показувати `Up (healthy)` замість просто `Up`.

---

### Крок 4: Створення runbook

Створи файл `monitoring/runbook.md`:

```bash
cat > monitoring/runbook.md << 'EOF'
# Runbook: training-project

## Операційні команди

### Перевірка стану сервісу
```bash
# Flask-сервіс
sudo systemctl status training-app --no-pager

# Healthcheck endpoint
curl -s http://localhost:5000/health

# PostgreSQL контейнер
sudo bash -c 'cd /opt/training-app && docker compose ps'
```

### Перегляд логів
```bash
# Логи Flask (systemd)
sudo journalctl -u training-app -n 50 --no-pager

# Логи PostgreSQL (Docker)
sudo docker compose -f /opt/training-app/docker-compose.yml logs db --tail=50

# Логи watchdog
tail -50 /var/log/training-app/healthcheck.log

# Alertи
cat /var/log/training-app/alerts.log
```

### Перезапуск сервісів
```bash
# Перезапуск Flask
sudo systemctl restart training-app

# Перезапуск PostgreSQL контейнера
sudo bash -c 'cd /opt/training-app && docker compose restart db'

# Повний перезапуск усього стеку
sudo systemctl restart training-app
sudo bash -c 'cd /opt/training-app && docker compose down && docker compose up -d'
```

## Disaster Recovery

### Якщо VM недоступна (з хоста)
```bash
cd 10_Implementation/01_vm
vagrant status
vagrant up        # якщо зупинена
vagrant reload    # якщо зависла
```

### Якщо Flask не стартує після деплою
1. Перевір journalctl: `sudo journalctl -u training-app -n 100`
2. Перевір .env файл: `sudo cat /opt/training-app/.env`
3. Перевір symlink: `ls -la /opt/training-app/app.py`
4. Перевір venv: `/opt/training-app/venv/bin/python -c "import flask; print('OK')"`

### Якщо PostgreSQL не стартує
1. Перевір логи Docker: `sudo docker compose -f /opt/training-app/docker-compose.yml logs db`
2. Перевір .env: `cat /opt/training-app/.env | grep POSTGRES`
3. Перевір volume: `sudo docker volume ls`

## Відомі проблеми

### WSL + ansible.cfg (world-writable warning)
**Проблема:** Ansible ігнорує ansible.cfg з попередженням "world writable directory"
**Рішення:** Завжди запускай з `ANSIBLE_CONFIG=./ansible.cfg`
```bash
ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory.ini playbook.yml
```

### ssh vagrant@192.168.56.10: Permission denied
**Проблема:** Прямий SSH без ключа не працює
**Рішення:** Використовуй `ssh devvm-vagrant` (налаштовано в ~/.ssh/config) або `vagrant ssh`
EOF
```

---

### Крок 5: Оновлення Ansible playbook — розгортання watchdog

Відкрий `training-project/ansible/playbook.yml` і додай перед секцією `handlers:` три нові задачі:

```yaml
    - name: Створити директорію для логів моніторингу
      file:
        path: /var/log/training-app
        state: directory
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'

    - name: Розгорнути watchdog-скрипт
      copy:
        src: "{{ playbook_dir }}/../monitoring/healthcheck.sh"
        dest: /opt/training-app/healthcheck.sh
        owner: "{{ app_user }}"
        group: "{{ app_user }}"
        mode: '0755'

    - name: Налаштувати cron для watchdog (кожну хвилину)
      cron:
        name: "training-app healthcheck"
        user: "{{ app_user }}"
        minute: "*"
        hour: "*"
        job: "/opt/training-app/healthcheck.sh >> /var/log/training-app/healthcheck.log 2>&1"
        state: present
```

---

### Крок 6: Збереження змін у Git та розгортання

```bash
cd ~/Desktop/\!KHPI/DevOps/AI_ASSISTANT/devops-ai-assistant
git add training-project/monitoring/
git add training-project/docker-compose.yml
git add training-project/ansible/playbook.yml
git commit -m "feat: add monitoring watchdog, Docker healthcheck and runbook"
git push
```

Тепер розгорнемо зміни через Ansible (з PowerShell або через WSL):

```powershell
wsl -d Ubuntu -- bash -c "cd '/mnt/c/Users/chapa/Desktop/!KHPI/DevOps/AI_ASSISTANT/devops-ai-assistant/training-project/ansible' && ANSIBLE_CONFIG=./ansible.cfg ansible-playbook -i inventory.ini playbook.yml -e 'db_password=Training2024'"
```

**Очікуваний результат:** нові задачі `changed`, решта `ok`.

---

### Крок 7: Перевірка результатів на VM

Підключись до VM:

```bash
ssh devvm-vagrant
```

Перевірка watchdog-скрипту:

```bash
# Переконаємось, що скрипт є та має права виконання
ls -la /opt/training-app/healthcheck.sh

# Запускаємо вручну перший раз
/opt/training-app/healthcheck.sh

# Дивимось лог
cat /var/log/training-app/healthcheck.log
```

**Очікуваний результат:**
```text
2026-05-07T10:30:01Z OK /health returned HTTP 200
```

Перевірка cron:

```bash
# Дивимось задачі cron для користувача training
sudo crontab -u training -l
```

**Очікуваний результат:**
```text
* * * * * /opt/training-app/healthcheck.sh >> /var/log/training-app/healthcheck.log 2>&1
```

Перевірка Docker HEALTHCHECK:

```bash
sudo bash -c 'cd /opt/training-app && docker compose ps'
```

**Очікуваний результат:** колонка `STATUS` показує `Up (healthy)`.

---

### Крок 8: Тестування alert-механізму

Симулюємо збій Flask: зупинимо сервіс і спостерігатимемо за реакцією watchdog.

На **VM**:

```bash
# Зупиняємо Flask-сервіс
sudo systemctl stop training-app

# Чекаємо кілька хвилин поки cron запустить watchdog 3+ рази
# або запускаємо вручну 3 рази для швидкої демонстрації
/opt/training-app/healthcheck.sh
/opt/training-app/healthcheck.sh
/opt/training-app/healthcheck.sh

# Перевіряємо лог
tail -10 /var/log/training-app/healthcheck.log

# Перевіряємо alert
cat /var/log/training-app/alerts.log
```

**Очікуваний результат у healthcheck.log:**
```text
2026-05-07T10:31:01Z ERROR /health returned HTTP 000 (fail 1/3)
2026-05-07T10:31:01Z ERROR /health returned HTTP 000 (fail 2/3)
2026-05-07T10:31:01Z ALERT training-app healthcheck failed 3 times in a row...
```

Відновлюємо сервіс:

```bash
sudo systemctl start training-app
sleep 2
curl http://localhost:5000/health

# Перевіряємо що watchdog знову показує OK
/opt/training-app/healthcheck.sh
tail -5 /var/log/training-app/healthcheck.log
```

**Очікуваний результат:**
```text
2026-05-07T10:32:01Z OK /health returned HTTP 200
```

---

### Крок 9: Діагностика через journalctl та docker logs

Повторно симулюємо збій і відпрацьовуємо алгоритм діагностики з runbook.

На **VM**, зупиняємо сервіс:

```bash
sudo systemctl stop training-app
```

Відпрацьовуємо алгоритм:

```bash
# Крок 1: підтверджуємо симптом
curl -s http://localhost:5000/health
sudo systemctl is-active training-app

# Крок 2: дивимось логи systemd (останні 20 рядків)
sudo journalctl -u training-app -n 20 --no-pager

# Крок 3: дивимось стан Docker залежностей
sudo bash -c 'cd /opt/training-app && docker compose ps'
sudo docker compose -f /opt/training-app/docker-compose.yml logs db --tail=10

# Крок 4: відновлюємо сервіс
sudo systemctl start training-app
sleep 2

# Крок 5: підтверджуємо відновлення
curl -s http://localhost:5000/health
sudo systemctl is-active training-app
```

Виходимо з VM:
```bash
exit
```

---

### Крок 10: Фінальна перевірка та коміт

Переконаємось, що watchdog працює автоматично (через cron).

На **хості**, зачекай 2 хвилини після відновлення сервісу, потім:

```bash
ssh devvm-vagrant "tail -5 /var/log/training-app/healthcheck.log"
```

**Очікуваний результат:** кілька рядків `OK /health returned HTTP 200` з різними timestamp — cron автоматично запускав watchdog.

Фінальний коміт результатів:

```bash
cd ~/Desktop/\!KHPI/DevOps/AI_ASSISTANT/devops-ai-assistant
git add -A
git commit -m "docs: complete Lab 10 monitoring setup"
git push
```

---

## ✅ Результат виконання роботи

- [ ] Створено `monitoring/healthcheck.sh` — watchdog-скрипт з логуванням та alerting
- [ ] Оновлено `docker-compose.yml` — PostgreSQL контейнер має `healthcheck` і показує `Up (healthy)`
- [ ] Створено `monitoring/runbook.md` — операційна документація
- [ ] Ansible playbook розгортає watchdog та налаштовує cron
- [ ] Скрипт записує результати в `/var/log/training-app/healthcheck.log`
- [ ] При 3 невдачах поспіль з'являється запис у `alerts.log`
- [ ] Ти вмієш читати логи через `journalctl` та `docker compose logs`
- [ ] Ти відпрацював алгоритм діагностики та відновлення сервісу

---

## ❓ Контрольні питання

1. Чому `systemctl status` недостатньо для моніторингу — що він не перевіряє?
2. Чому watchdog не реагує на першу помилку, а чекає 3 поспіль? Що таке "alert fatigue"?
3. У чому різниця між `docker compose ps` зі статусом `Up` та `Up (healthy)`? Що забезпечує цю різницю?
4. Чому watchdog і systemd не замінюють одне одного — яка функція кожного?
5. Що таке SLI та SLO? Наведи приклад SLI та SLO для нашого `training-project`.
6. Після інциденту ти виправив проблему вручну на VM. Чому це проблема з точки зору DevOps? Що таке "configuration drift"?
7. Які три стовпи Observability? Які інструменти з нашого стеку відносяться до кожного стовпа?
