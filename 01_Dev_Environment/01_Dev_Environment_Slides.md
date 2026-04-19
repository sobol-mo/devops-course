---
marp: true
theme: default
paginate: true
backgroundColor: #1a1a2e
color: #eaeaea
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 24px;
  }
  h1 {
    color: #e94560;
    font-size: 52px;
    border-bottom: 3px solid #e94560;
    padding-bottom: 10px;
  }
  h2 {
    color: #0f3460;
    background: #e94560;
    padding: 6px 16px;
    border-radius: 6px;
    display: inline-block;
    font-size: 34px;
  }
  h3 { color: #e94560; }
  code {
    background: #0f3460;
    color: #53d8fb;
    padding: 2px 8px;
    border-radius: 4px;
  }
  table {
    font-size: 20px;
    border-collapse: collapse;
    width: 100%;
    background: #0f1c3f;
  }
  tr { background: #0f1c3f !important; }
  th { background: #e94560 !important; color: white; padding: 8px; }
  td { padding: 8px; border-bottom: 1px solid #2a3a6a; color: #eaeaea; background: #0f1c3f !important; }
  tr:nth-child(even) td { background: #162040 !important; }
  code {
    background: #0f1c3f !important;
    color: #53d8fb;
    padding: 2px 8px;
    border-radius: 4px;
  }
  pre { background: #0f1c3f !important; border-radius: 8px; padding: 12px; }
  pre code { background: transparent !important; padding: 0; }
  blockquote {
    border-left: 4px solid #e94560;
    padding-left: 16px;
    color: #aaa;
    font-style: italic;
  }
---
# Основи DevOps

## Тема 1: Нам потрібна безпечна пісочниця

**Dev Environment & Virtualization**

---

### 🚨 Проблема

```text
Студент вирішив перевірити нову конфігурацію nginx
прямо на Production-сервері.

"Так швидше — навіщо будувати тестове середовище?"

48 хвилин пізніше...

❌ Сервіс недоступний
❌ Реальні користувачі не можуть зайти
❌ Rollback зайняв 3 години через ручне налаштування
```

> DevOps-правило №1: **Ніколи не тестуй на Production.**

---

## 🏎️ Метафора: Тренувальний полігон

**Можна перевернутись, заїхати в кювет, зупинитись посеред смуги.**
**Після кожної аварії — «скидаємо» і пробуємо знову.**

&nbsp;

```text
🏎️ Dev Environment  →  🛣️ Staging  →  🏙️ Production
   (наш полігон)          (репетиція)     (реальна траса)
```

---

## 🌍 Три середовища: Dev → Staging → Production

| Середовище     | Хто використовує      | Дані            | Ризик   |
| -------------- | --------------------- | --------------- | ------- |
| **Development**  | Розробник / студент   | Тестові / фейкові | 🟢 Низький |
| **Staging**      | QA, замовник          | Копія реальних  | 🟡 Середній |
| **Production**   | Реальні користувачі   | Справжні дані   | 🔴 Високий |

&nbsp;

> Сьогодні ми будуємо **Development** — локальну VM, де дозволено все.

---

## 💡 Що таке віртуалізація?

```text
БЕЗ ВІРТУАЛІЗАЦІЇ          З ВІРТУАЛІЗАЦІЄЮ
──────────────────         ─────────────────────────────
[ Web Server ]             [ ФІЗИЧНЕ ЗАЛІЗО            ]
[ DB Server  ]      →      [ Гіпервізор                ]
[ Mail Server]             [ VM 1 ] [ VM 2 ] [ VM 3 ]
[ 3 фіз. сервери ]         [ один сервер, 3 ОС ]
5-15% завантаження         60-80% завантаження
```

**Гіпервізор** = «диригент», що розподіляє ресурси між VM

---

## 🔧 Гіпервізор Тип 1 vs Тип 2

| &nbsp;             | **Тип 1 — Bare-Metal**    | **Тип 2 — Hosted**      |
| -----------------  | ------------------------- | ----------------------- |
| Встановлюється     | Напряму на залізо         | Поверх хостової ОС      |
| Продуктивність     | ⭐⭐⭐ Максимальна         | ⭐⭐ Дещо менша          |
| Де використовується| Датацентри, хмара         | Локальна розробка       |
| Складність         | 🔴 Висока                 | 🟢 Низька               |
| Приклади           | ESXi, KVM, Hyper-V        | **VirtualBox**, Parallels |

&nbsp;

> У нашому курсі: **VirtualBox** (Тип 2) — безкоштовний, крос-платформний

---

## 🐳 VM vs Docker: що обрати?

| &nbsp;             | **VM**                   | **Docker Container**     |
| -----------------  | ------------------------ | ------------------------ |
| Ізоляція           | Повна ОС                 | Тільки процеси           |
| Розмір             | Сотні MB                 | Мегабайти                |
| Запуск             | Хвилини                  | Секунди                  |
| Власне ядро ОС     | ✅ Так                   | ❌ Ні (від хоста)        |
| `systemd`          | ✅ Є                     | ❌ Немає                  |
| Мережевий стек     | ✅ Повноцінний           | ⚠️ Обмежений             |

&nbsp;

> Наш агент запускається як **`systemd`-сервіс** → **потрібна VM**

---

## 📦 Infrastructure as Code — перше знайомство

**Проблема ручного налаштування:**

```text
Налаштував VM через GUI → VM зламалась → починай з нуля 😢
```

**Рішення — Vagrant + Vagrantfile:**

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"   # Ubuntu 22.04 LTS
  config.vm.hostname = "devops-sandbox"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048   # 2 GB RAM
    vb.cpus   = 2      # 2 ядра CPU
  end
end
```

```bash
vagrant up    # ← одна команда замість 20 кліків у GUI
```

---

## 🔑 Чому це Infrastructure as Code?

&nbsp;

- **Відтворюваність** — однакова VM у всіх членів команди ✅
- **Версіонування** — `Vagrantfile` зберігається в Git ✅
- **Відновлення** — VM зламалась? `vagrant destroy && vagrant up` ✅
- **Передача** — надіслав `Vagrantfile` колезі → він отримає ту саму VM ✅

&nbsp;

> **Той самий принцип** — в Темі 6 буде Terraform для хмарних серверів.
> Vagrantfile = Terraform для локальних VM.

---

## 🛠️ Базові команди Vagrant

```bash
# Створити і запустити VM (перший раз — завантажує box та провізіонує)
vagrant up

# Підключитися по SSH до VM
vagrant ssh

# Зупинити VM (зберігає стан)
vagrant halt

# Видалити VM повністю
vagrant destroy

# Зробити знімок стану VM
vagrant snapshot save clean-install

# Відновити знімок
vagrant snapshot restore clean-install
```

---

## 🔍 Де це в нашому проєкті?

```text
devops-ai-assistant/
└── 10_Implementation/
    └── 01_vm/
        └── Vagrantfile   ← ваша Dev Environment в одному файлі
```

&nbsp;

```bash
git clone https://github.com/sobol-mo/devops-course.git
cd devops-course/DevOps/devops-ai-assistant/10_Implementation/01_vm/
vagrant up
vagrant ssh
```

**Результат:** повноцінна Ubuntu 22.04 VM за 3-5 хвилин

---

## ✅ Підсумок Теми 1

&nbsp;

1. **Dev/Staging/Prod** — три окремі середовища з різними ролями та ризиками
2. **Гіпервізор** — програма, що ділить фізичне залізо між VM
3. **Тип 1** (датацентри) vs **Тип 2** (VirtualBox — для нас)
4. **VM vs Docker** — VM обираємо для повноцінного `systemd` і мережевого стека
5. **Vagrant** — перший практичний приклад **Infrastructure as Code**

&nbsp;

### 👉 Наступна тема

**Тема 2: Навчитися орієнтуватися всередині сервера**
*(Linux: файлова система, команди, користувачі, права доступу)*

---

## ❓ Питання для обговорення

1. Ваш колега хоче протестувати нову конфігурацію **прямо на Production** — «так швидше». Що ви йому скажете?
2. Яка різниця між VM і Docker з точки зору **ізоляції**? Коли використовувати кожен?
3. Чому `Vagrantfile` — це **Infrastructure as Code**, а не просто «скрипт»?
