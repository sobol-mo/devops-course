# DevOps AI Assistant

> Навчальний репозиторій до курсу **«Основи DevOps»**.
> Викладач: [ваше ім'я], університет, [рік].

---

## Про проєкт

Цей репозиторій — навчальна, відкрита версія реального pet-проєкту AI-асистента. На його прикладі ми вивчаємо інфраструктурні практики, з яких складається сучасний DevOps: від створення Dev Environment до автоматизованого CI/CD конвеєра.

Асистент будується на основі [OpenClaw](https://github.com/openclaw/openclaw) — відкритого AI-агента для особистих завдань, інтегрованого з Telegram, Google Calendar та іншими сервісами.

---

## Структура репозиторію

```
devops-ai-assistant/
├── 01_Architecture/          # Архітектура системи: схеми, MVP, база даних
│   ├── System_Architecture.md
│   ├── MVP_Scope.md
│   ├── Quick_Start_Guide.md
│   ├── Data_Schema.md
│   └── schemas/
│       └── 001_mvp_schema.sql
│
├── 10_Implementation/        # Реалізація інфраструктури
│   ├── ansible/              # IaC: Ansible playbooks для налаштування сервера
│   │   ├── playbook-openclaw-setup.yml
│   │   ├── inventory.ini     # Налаштуйте IP вашого VPS тут
│   │   ├── ansible.cfg
│   │   └── templates/
│   │
│   ├── terraform/            # Vagrant VM для локального Dev Environment
│   │   ├── Vagrantfile
│   │   ├── README.md
│   │   └── QUICK_START.md
│   │
│   └── openclaw/
│       └── clawd/            # Конфігурація та опис агента
│
└── README.md                 # Цей файл
```

---

## Тематичний план курсу

Курс складається з 11 модулів. Детальний тематичний план знаходиться у репозиторії викладача.

| Модуль | Тема |
| ------ | ---- |
| 0      | Навіщо це все? Філософія та принципи DevOps |
| 1      | Нам потрібна безпечна пісочниця — Віртуалізація |
| 2      | Основи Linux для DevOps-інженера |
| 3      | Мережева доступність та ізоляція |
| 4      | Безпечний віддалений доступ — SSH |
| 5      | Код має бути під контролем — Git |
| 6      | Infrastructure as Code — Ansible |
| 7      | Агент має працювати 24/7 — systemd |
| 8      | Контейнеризація — Docker |
| 9      | CI/CD: автоматизація конвеєра |
| 10     | Monitoring та Observability |

---

## Швидкий старт (для студентів)

```bash
# Клонуємо репозиторій
git clone https://github.com/YOUR_USERNAME/devops-ai-assistant.git
cd devops-ai-assistant

# Ознайомтеся з архітектурою
cat 01_Architecture/System_Architecture.md

# Налаштуйте inventory для Ansible
nano 10_Implementation/ansible/inventory.ini
# Замініть YOUR_VPS_IP на IP-адресу вашої VM
```

---

## Технологічний стек

| Шар | Технологія |
| --- | --- |
| Агент (AI) | OpenClaw (Node.js) |
| Конфігурація | Ansible |
| Dev VM | Vagrant + VirtualBox |
| БД (агент) | SQLite + sqlite-vec |
| Хмарна інфраструктура | Hetzner Cloud (VPS) |
| CI/CD | GitHub Actions |

---

## Ліцензія

Навчальні матеріали: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
