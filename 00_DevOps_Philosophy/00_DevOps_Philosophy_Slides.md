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
    font-size: 22px;
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

## Тема 0: Навіщо це все?

**Філософія та принципи DevOps**

---

### Метафора DevOps: Ефект Червоної Королеви

> "Well, in our country," said Alice, still panting a little, "you'd generally get to somewhere else — if you ran very fast for a long time, as we've been doing."
>
> "A slow sort of country!" said the Queen. "**Now, here, you see, it takes all the running you can do, to keep in the same place.** If you want to get somewhere else, you must run at least **twice as fast as that!**"
>
> — *Lewis Carroll, «Through the Looking-Glass»*

---

### Метафора DevOps: Ефект Червоної Королеви

> «Ну, у нас, — сказала Аліса, все ще трохи важко дихаючи, — зазвичай потрапляєш в інше місце, якщо бігти дуже швидко і довго, як ми щойно робили».
>
> «Яка повільна країна! — вигукнула Королева. — **Тут, як бачиш, треба бігти щосили, щоб тільки залишитися на одному місці.** А якщо хочеш потрапити в інше місце, треба бігти принаймні **вдвічі швидше!**»
>
> — *Льюїс Керролл, «Аліса в Зазеркаллі»*

---

### Ефект Червоної Королеви (Red Queen Hypothesis)

**Контекст:** Аліса здивована тим, що після довгого бігу вони залишилися на тому ж місці. Королева пояснює: у Зазеркаллі нерухомість вимагає максимальних зусиль.

**В DevOps:** Щоб система просто *працювала* (стабільність), ми маємо постійно розвиватися та адаптуватися до змін. Це основа «Гіпотези Червоної Королеви»: **потрібно постійно бігти, щоб просто зберігати поточну позицію.**

---

> Не інструменти. Культура.

---

## 🎯 Питання, з якого все починається

![bg right:40% contain](./images/change_vs_stability.png)

**Ви написали код для AI-асистента.**
**Хто відповідає за те, щоб він працював о 3 годині ночі?**

```text
Розробник? → "Я написав код, моя робота зроблена"
Адміністратор? → "Я не знаю, що цей код робить"
```

> DevOps народився саме тут — у цій прірві між двома командами.

---

## 🧱 Стіна між Dev та Ops

![bg contain](./images/wall.png)

---

## 🌉 Agile та DevOps: де межа?

![bg contain](./images/wall4.png)

---

## 💡 Що таке DevOps?

![bg right:40% contain](./images/wall2.png)

> **DevOps** — це культура та набір практик, що об'єднують розробку та експлуатацію.

### ❌ DevOps — це НЕ

- Посада "DevOps Engineer"
- Набір інструментів (Docker...)
- Окремий відділ

### ✅ DevOps — це

- **Спосіб мислення**
- Спільна відповідальність від коду до Production
- **«The Phoenix Project»** — культова книга, що пояснює DevOps через художню розповідь

---

## 🏗️ Модель CALMS

![bg right:45% contain](./images/calms.png)

- **C**ulture (Культура) — люди важливіші за процеси
- **A**utomation (Автоматизація) — автоматизуй все
- **L**ean (Ощадність) — маленькі часті зміни
- **M**easurement (Вимірювання) — вимірюй, щоб покращувати
- **S**haring (Ділення) — відкрито ділися знаннями, культура blame-free (без пошуку винних)

---

## 🔄 Три шляхи DevOps

Три шляхи — це ще більш узагальнений фреймворк з книги "The DevOps Handbook"

![bg right:52%](./images/three_ways.png)

**1️⃣ Flow** — прискорюємо шлях
від коду до користувача

**2️⃣ Feedback** — моніторинг і
алерти повертаються до розробника

**3️⃣ Continual Learning** —
вчимося на помилках, без blame

---

## 📊 DORA-метрики: як виміряти DevOps?

Дослідницька група DORA (DevOps Research and Assessment) виявила 4 ключові метрики, що відрізняють "елітні" DevOps-команди від середніх:

| Метрика                  | Що вимірює                               | "Еліта"                          |
| ------------------------------- | ------------------------------------------------- | ------------------------------------- |
| **Deployment Frequency**  | Як часто виходять релізи     | Кілька разів на день |
| **Lead Time for Changes** | Від коміту до Production               | < 1 години                      |
| **Change Failure Rate**   | % змін, що потребують відкату або хотфіксу | < 15% (для еліти < 5%) |
| **Time to Restore**       | Час відновлення після збою | < 1 години                      |

> 🔬 Джерело: Google DORA Research — дослідження 33 000+ команд

---

## 📚 Шлях коду: від розробника до Production

```text
 РОЗРОБНИК           GIT             CI/CD           STAGING         PRODUCTION
     │                 │               │                 │                │
  пише код  ──► commit/push ──► авто-тести ──► перевірка ──► випуск
                               збірка (build)   вручну або    для всіх
                                                 авто         користувачів
```

- **Code/Commit** — написання та фіксація змін у Git
- **CI/CD** — автоматична збірка та тестування
- **Staging** — перевірка у «майже бойових» умовах
- **Production** — реальна робота зі справжніми користувачами

---

## 🔍 DevOps у нашому проєкті — структура репозиторію

```text
My_AI_Assistant/ репозиторій
├── 01_Architecture/      ← Архітектура описана в коді
├── DevOps/               ← Матеріали курсу
│   └── devops-ai-assistant/
│       ├── 10_Implementation/
│       │   ├── ansible/  ← IaC (Automation ✅)
│       │   └── terraform/← Provisioning (Automation ✅)
│       └── 01_Architecture/← Docs as Code (Sharing ✅)
```

**Все в одному місці. Все під контролем версій. Все відтворюване.**

---

## 🔒 DevOps у нашому проєкті — ізоляція та безпека

![bg right:55% contain](./images/ssh_isolation.png)

Агент **герметично ізольований**:

- 🛡 **Firewall**: ззовні відкритий лише порт `22` (SSH)
- 👤 **Окремий користувач** `openclaw` — без `sudo`
- 🔒 Агент слухає лише **`localhost:18789`** — не `0.0.0.0`
- 🚇 Доступ до UI — лише через **SSH-тунель**

> Якщо зловмисник зламає агента — він потрапить у «пісочницю» без прав на решту системи.

---

## ✅ Підсумок Модуля 0

&nbsp;

1. DevOps народився, коли Dev і Ops мали **протилежні цілі**
2. DevOps — це **культура**, а не набір інструментів
3. Модель **CALMS** описує 5 принципів
4. **Три шляхи** = Flow + Feedback + Continual Learning
5. **DORA-метрики** дозволяють виміряти ефективність

&nbsp;

### 👉 Наступний модуль

**Модуль 1: Нам потрібна безпечна пісочниця**
*(Як і чому ми створюємо Dev Environment у віртуальній машині)*

---

## ❓ Питання для обговорення

1. Чому компанія **не може** "впровадити DevOps", просто встановивши Jenkins?
2. Яка з DORA-метрик, на вашу думку, **найважча** для покращення і чому?
3. Де в нашому репозиторії ви бачите принцип **Sharing**?
