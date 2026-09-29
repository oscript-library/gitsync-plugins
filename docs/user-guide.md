# Пользовательская документация gitsync-plugins

## Общие сведения

Плагины gitsync расширяют возможности синхронизации конфигураций 1С с git-репозиторием. Каждый плагин решает свою задачу: проверка авторов, установка тегов, выгрузка в формате EDT и т.д.

### Управление плагинами

Плагинами управляют через утилиту `gitsync`:

```
gitsync p e <имя_плагина>   — включить плагин
gitsync p d <имя_плагина>   — отключить плагин
gitsync p d -a              — отключить все плагины
gitsync p l                 — список включённых плагинов
gitsync p l -a              — список всех доступных плагинов (включая отключённые)
gitsync p i -f <файл.ospx>  — установить плагин из пакета
```

**Важно:** `gitsync p l` без ключа `-a` показывает **только включённые** плагины. Чтобы увидеть полный перечень, используйте `gitsync p l -a`.

Большинство параметров плагинов можно задать двумя способами: через аргумент командной строки `gitsync` и через переменную окружения.

---

## Плагин `check-authors`

**Назначение:** блокирует синхронизацию, если автор версии хранилища отсутствует в файле `AUTHORS`.

**Команды:** `sync`

**Параметры:** нет.

**Принцип работы:** перед началом цикла обработки версий проверяет таблицу истории хранилища — каждый автор версии должен быть сопоставлен git-пользователю в файле `AUTHORS`. Несопоставленные авторы вызывают исключение с указанием количества проблемных версий.

---

## Плагин `check-comments`

**Назначение:** проверка заполнения и содержимого комментариев к версиям хранилища.

**Команды:** `sync`

**Поведение без `--error-comment`:** при обнаружении проблем (пустой комментарий, нехватка упоминаний задач) в лог пишется `КРИТИЧНАЯОШИБКА`, но синхронизация **продолжается**. Код возврата — 0. Это позволяет вести мониторинг без прерывания процесса.

**С `--error-comment`:** при любой из проверок синхронизация **останавливается** с исключением и кодом возврата 1.

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--error-comment` | `-C` | `false` | — | Вызывать ошибку при отсутствии комментария |
| `--task-prefix` | — | `""` | `GITSYNC_TASK_PREFIX` | Префикс задачи для поиска в комментарии |
| `--task-pattern` | — | `""` | `GITSYNC_TASK_PATTERN` | Паттерн задачи (регулярное выражение) |
| `--min-task-count` | — | `0` | — | Минимальное количество упоминаний задач |
| `--max-task-count` | — | `0` | — | Максимальное количество упоминаний задач |
| `--author-presentation` | — | `false` | `GITSYNC_AUTHOR_PRESENTATION` | Использовать представление автора в сообщениях |
| `--repair-quotes` | — | `false` | `GITSYNC_REPAIR_QUOTES` | Заменять Unicode-кавычки на ASCII |

### Примеры

```
# Требовать комментарий (с ошибкой)
gitsync sync --error-comment /path/to/storage /path/to/src

# Проверить наличие префикса задачи "RM-12345" в комментарии
gitsync sync --task-prefix RM

# Заменить кавычки-ёлочки на прямые
gitsync sync --repair-quotes /path/to/storage /path/to/src
```

---

## Плагин `disable-support`

**Назначение:** снимает конфигурацию с поддержки перед выгрузкой в исходники — через API конфигуратора (`СнятьКонфигурациюСПоддержки`).

**Команды:** все (подключается неявно)

**Параметры:** нет.

**Зачем снимать поддержку:** конфигурация на поддержке поставщика содержит в выгрузке большой бинарный `.cf`-файл с полной конфигурацией вендора. Снятие поддержки исключает его из исходников, что:
- В разы сокращает размер git-репозитория
- Делает diff читаемым (нет изменений от обновлений поставщика)
- Разблокирует объекты конфигурации для редактирования

Снятие поддержки выполняется **перед** каждой выгрузкой версии — конфигурация в хранилище остаётся на поддержке, меняется только выгруженное состояние.

---

## Плагин `drop-config-dump`

**Назначение:** отключает версионирование `ConfigDumpInfo.xml` и удаляет его после выгрузки.

**Команды:** `init`, `sync`

**Параметры:** нет.

**Принцип работы:**
1. При активизации отключает несовместимый плагин `increment`
2. Удаляет `ConfigDumpInfo.xml` из каталога рабочей копии и каталога выгрузки
3. Добавляет `ConfigDumpInfo.xml` в `.gitignore`
4. Коммитит изменение `.gitignore`

---

## Плагин `drop-support`

**Назначение:** удаляет информацию о поддержке из выгруженных исходников — напрямую, без использования конфигуратора. Решает ту же задачу, что и `disable-support`, но работает с папкой `Ext/ParentConfigurations/`.

**Команды:** `sync`

**Параметры:** нет.

**Отличие от `disable-support`:** `disable-support` требует отдельное действие в конфигураторе — вызов `СнятьКонфигурациюСПоддержки`. `drop-support` делает то же самое прямыми файловыми операциями — удаляет `*.cf` из `Ext/ParentConfigurations/` и затирает `ParentConfigurations.bin`.

**Принцип работы:**
1. Удаляет `*.cf` из `Ext/ParentConfigurations/`
2. Записывает в `ParentConfigurations.bin` пустую информацию о поддержке
3. Добавляет `Ext/ParentConfigurations/*.cf` в `.gitignore`
4. Коммитит изменение `.gitignore`

---

## Плагин `edtExport`

**Назначение:** выгрузка конфигурации в формате EDT (1C:Enterprise Development Tools).

**Требования:** установленные EDT и утилита `ring` или `1cedtcli`.

**Команды:** `sync`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--project-name` | `-PN` | `""` | `GITSYNC_PROJECT_NAME` | Имя проекта в EDT |
| `--workspace-location` | `-W` | `""` | `GITSYNC_WORKSPACE_LOCATION` | Путь к рабочей области EDT |
| `--base-project-name` | `-BP` | `""` | `GITSYNC_BASE_PROJECT_NAME` | Базовый проект (для расширений) |
| `--edt-version` | `-EDT` | `""` | `GITSYNC_EDT_VERSION` | Версия EDT. Если не задана — автоопределение |

### Примеры

```
# Выгрузка конфигурации в формате EDT
gitsync sync --project-name MyConfig --workspace-location /path/to/workspace /path/to/storage /path/to/src

# Для расширения с указанием базового проекта
gitsync sync --project-name MyExt --workspace-location /path/to/ws --base-project-name BaseConfig /path/to/storage /path/to/src

# С указанием версии EDT
gitsync sync --project-name MyConfig --workspace-location /path/to/ws --edt-version 2024.2.5 /path/to/storage /path/to/src
```

---

## Плагин `increment`

**Назначение:** инкрементальная выгрузка конфигурации в исходники. Выгружаются только изменённые объекты.

**Команды:** все (подключается неявно)

**Параметры:** нет.

**Принцип работы:**
1. Проверяет наличие `ConfigDumpInfo.xml` в рабочей копии
2. Через `DumpConfigToFiles -getChanges` определяет возможность инкрементальной выгрузки
3. При выгрузке использует флаг `-update` и дамп изменений `ConfigDumpInfo.xml`
4. Сохраняет список изменённых файлов в `dumplist.txt` для использования другими плагинами

**Несовместимость с другими плагинами:**

- **`drop-config-dump`** — удаляет `ConfigDumpInfo.xml`, который необходим `increment` для отслеживания изменений. При включении `drop-config-dump` автоматически отключает `increment`.
- **`use-ibcmd`** — предоставляет собственную реализацию инкрементальной выгрузки (через флаг `--increment`). При включении `use-ibcmd` автоматически отключает `increment` и включает свой параметр `--increment`.

Не рекомендуется включать `increment` одновременно с этими плагинами.

---

## Плагин `limit`

**Назначение:** ограничение номеров выгружаемых версий хранилища.

**Команды:** `sync`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--limit` | `-l` | `0` | `GITSYNC_LIMIT` | Не более N версий от текущей |
| `--minversion` | — | `0` | — | Минимальный номер версии |
| `--maxversion` | — | `0` | — | Максимальный номер версии |

### Примеры

```
# Выгрузить не более 3 версий
gitsync sync --limit 3 /path/to/storage /path/to/src

# Выгрузить версии с 5 по 10
gitsync sync --minversion 5 --maxversion 10 /path/to/storage /path/to/src
```

---

## Плагин `replace-authors`

**Назначение:** замена автора коммита через специальный маркер в комментарии к версии хранилища.

**Команды:** все (подключается неявно)

**Параметры:** нет.

**Принцип работы:** при синхронизации ищет в комментариях версий строку `--GitSyncAuthor НовыйАвтор`. Если находит — заменяет автора коммита на указанного. Новый автор должен быть в файле `AUTHORS`. Строка с командой замены удаляется из комментария.

### Пример

В хранилище версия от пользователя «Администратор» с комментарием:
```
Исправление ошибки №12345
--GitSyncAuthor Иванов
```

В git коммит будет создан от имени «Иванов» с комментарием:
```
Исправление ошибки №12345
```

---

## Плагин `roboCopy`

**Назначение:** (Windows) заменяет штатный механизм копирования исходников на `robocopy` для обхода ограничения на длину пути.

**Команды:** `sync`

**Параметры:** нет.

**Принцип работы:** при очистке и перемещении файлов в каталог рабочей копии использует `robocopy` вместо стандартных файловых операций. Это позволяет работать с путями длиннее 260 символов.

---

## Плагин `smart-tags`

**Назначение:** автоматическая расстановка тегов git при изменении версии конфигурации.

**Команды:** `sync`, `export`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--skip-exists-tags` | `-S` | `false` | `GITSYNC_SKIP_EXISTS_TAGS` | Пропускать ошибку, если тег уже существует |
| `--numerator` | `-N` | `false` | `GITSYNC_NUMERATOR` | Добавлять тег `v.X` по номеру версии хранилища |
| `--tags-prefix` | `-T` | `""` | `GITSYNC_TAGS_PREFIX` | Префикс для всех создаваемых тегов |

### Примеры

```
# Тег по версии конфигурации с префиксом
gitsync sync --tags-prefix vendor/ /path/to/storage /path/to/src
# Результат: тег vendor/1.3.220.1

# Тег-нумератор версий хранилища
gitsync sync --numerator /path/to/storage /path/to/src
# Результат: теги v.1, v.2, ...

# Комбинация префикса и нумератора
gitsync sync --numerator --tags-prefix release/ /path/to/storage /path/to/src
# Результат: тег release/1.3.220.1 и release/v.1, release/v.2, ...
```

---

## Плагин `sync-remote`

**Назначение:** синхронизация с удалённым git-репозиторием (pull/push).

**Команды:** `sync`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--push` | `-PS` | `false` | `GITSYNC_REMOTE_PUSH` | Отправлять изменения на удалённый репозиторий |
| `--pull` | `-G` | `false` | `GITSYNC_REMOTE_PULL` | Получать изменения перед синхронизацией |
| `--branch` | `-b` | `"master"` | `GITSYNC_REMOTE_BRANCH` | Имя ветки |
| `--push-tags` | `-T` | `false` | `GITSYNC_REMOTE_PUSH_TAGS` | Отправлять теги |
| `--push-n-commits` | `-n` | `0` | `GITSYNC_REMOTE_PUSH_N_COMMITS` | Промежуточный push через N коммитов |
| `--push-options` | `-O` | `""` | `GITSYNC_PUSH_OPTIONS` | Дополнительные параметры push (через `;`) |
| аргумент `URL` | — | — | `GITSYNC_REPO_URL` | URL удалённого репозитория |

### Примеры

```
# Получить изменения и отправить после синхронизации
gitsync sync --pull --push /path/to/storage /path/to/src https://github.com/user/repo.git

# С указанием ветки и отправкой тегов
gitsync sync --push --branch develop --push-tags /path/to/storage /path/to/src https://github.com/user/repo.git

# Промежуточный push каждые 10 коммитов
gitsync sync --push --push-n-commits 10 /path/to/storage /path/to/src https://github.com/user/repo.git
```

---

## Плагин `tool1CD`

**Назначение:** выгрузка конфигурации через утилиту `tool1CD` вместо штатных механизмов 1С.

**Ограничения:** не работает с серверными хранилищами (`TCP:` и `HTTP`). Неприменим для расширений.

**Команды:** `sync`, `clone`, `init`

**Параметры:** нет.

**Принцип работы:** читает таблицы версий (`VERSIONS`) и пользователей (`USERS`) напрямую из файловой базы хранилища (`1cv8ddb.1CD`), минуя конфигуратор 1С.

---

## Плагин `unpackForm`

**Назначение:** распаковка обычных форм 1С в исходные файлы.

**Команды:** `sync`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--rename-module` | `-R` | `false` | `GITSYNC_RENAME_MODULE` | Переименовать `module` → `Module.bsl` |
| `--rename-form` | `-F` | `false` | `GITSYNC_RENAME_FORM` | Переименовать `form` → `form.txt` |

### Примеры

```
# Распаковать формы с переименованием модулей
gitsync sync --rename-module /path/to/storage /path/to/src
```

---

## Плагин `use-ibcmd`

**Назначение:** выгрузка конфигурации через утилиту `ibcmd` (автономный сервер 1С).

**Примечание:** при активизации отключает плагин `increment`, перенимая его функцию инкрементальной выгрузки.

**Команды:** `sync`

### Параметры

| Параметр | Кратко | По умолчанию | Переменная окружения | Описание |
|---|---|---|---|---|
| `--ibcmd-data` | — | `""` | `GITSYNC_IBCMD_DATA` | Рабочий каталог ibcmd |
| `--ibcmd-dbms` | `-t` | `"MSSQLServer"` | `GITSYNC_IBCMD_DBMS` | Тип СУБД |
| `--ibcmd-db-server` | `-s` | `""` | `GITSYNC_IBCMD_DB_SERVER` | Адрес сервера БД |
| `--ibcmd-db-name` | `-n` | `""` | `GITSYNC_IBCMD_DB_NAME` | Имя БД |
| `--ibcmd-db-user` | `-U` | `""` | `GITSYNC_IBCMD_DB_USER` | Пользователь БД |
| `--ibcmd-db-pwd` | `-P` | `""` | `GITSYNC_IBCMD_DB_PWD` | Пароль пользователя БД |
| `--ibcmd-threads` | `-j` | `0` | `GITSYNC_IBCMD_THREADS` | Количество потоков |
| `--increment` | `-i` | `false` | `GITSYNC_IBCMD_INCREMENT` | Инкрементальная выгрузка |

### Примеры

```
# Выгрузка из файловой БД
gitsync sync --ibcmd-data /path/to/data /path/to/storage /path/to/src

# Выгрузка из серверной БД с 4 потоками
gitsync sync --ibcmd-db-server myserver --ibcmd-db-name mydb --ibcmd-db-user admin --ibcmd-db-pwd secret --ibcmd-threads 4 /path/to/storage /path/to/src
```

---

## Сводная таблица переменных окружения

| Переменная | Плагин | Параметр |
|---|---|---|
| `GITSYNC_SKIP_EXISTS_TAGS` | smart-tags | `--skip-exists-tags` |
| `GITSYNC_NUMERATOR` | smart-tags | `--numerator` |
| `GITSYNC_TAGS_PREFIX` | smart-tags | `--tags-prefix` |
| `GITSYNC_TASK_PREFIX` | check-comments | `--task-prefix` |
| `GITSYNC_TASK_PATTERN` | check-comments | `--task-pattern` |
| `GITSYNC_AUTHOR_PRESENTATION` | check-comments | `--author-presentation` |
| `GITSYNC_REPAIR_QUOTES` | check-comments | `--repair-quotes` |
| `GITSYNC_LIMIT` | limit | `--limit` |
| `GITSYNC_PROJECT_NAME` | edtExport | `--project-name` |
| `GITSYNC_WORKSPACE_LOCATION` | edtExport | `--workspace-location` |
| `GITSYNC_BASE_PROJECT_NAME` | edtExport | `--base-project-name` |
| `GITSYNC_EDT_VERSION` | edtExport | `--edt-version` |
| `GITSYNC_REMOTE_PUSH` | sync-remote | `--push` |
| `GITSYNC_REMOTE_PULL` | sync-remote | `--pull` |
| `GITSYNC_REMOTE_BRANCH` | sync-remote | `--branch` |
| `GITSYNC_REMOTE_PUSH_TAGS` | sync-remote | `--push-tags` |
| `GITSYNC_REMOTE_PUSH_N_COMMITS` | sync-remote | `--push-n-commits` |
| `GITSYNC_PUSH_OPTIONS` | sync-remote | `--push-options` |
| `GITSYNC_REPO_URL` | sync-remote | аргумент `URL` |
| `GITSYNC_RENAME_MODULE` | unpackForm | `--rename-module` |
| `GITSYNC_RENAME_FORM` | unpackForm | `--rename-form` |
| `GITSYNC_IBCMD_DATA` | use-ibcmd | `--ibcmd-data` |
| `GITSYNC_IBCMD_DBMS` | use-ibcmd | `--ibcmd-dbms` |
| `GITSYNC_IBCMD_DB_SERVER` | use-ibcmd | `--ibcmd-db-server` |
| `GITSYNC_IBCMD_DB_NAME` | use-ibcmd | `--ibcmd-db-name` |
| `GITSYNC_IBCMD_DB_USER` | use-ibcmd | `--ibcmd-db-user` |
| `GITSYNC_IBCMD_DB_PWD` | use-ibcmd | `--ibcmd-db-pwd` |
| `GITSYNC_IBCMD_THREADS` | use-ibcmd | `--ibcmd-threads` |
| `GITSYNC_IBCMD_INCREMENT` | use-ibcmd | `--increment` |
