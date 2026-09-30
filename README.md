# Домашнее задание №1 — развертывание HDFS-кластера

## Цель

Необходимо развернуть кластер HDFS, включающий:

* 3 DataNode;
* NameNode;
* Secondary NameNode.

После развертывания необходимо проверить целостность кластера и убедиться, что все 3 DataNode работают.

Для автоматического развёртывания используется скрипт `deploy_cluster.sh`.

---

## Архитектура кластера

Кластер состоит из четырёх виртуальных машин.

| Hostname     | IP-адрес     | Роль                          |
| ------------ | ------------ | ----------------------------- |
| `team-12-en` | `10.12.0.10` | DataNode                      |
| `team-12-nn` | `10.12.0.11` | NameNode + Secondary NameNode |
| `team-12-00` | `10.12.0.12` | DataNode                      |
| `team-12-01` | `10.12.0.13` | DataNode                      |

Таким образом:

```text
                    team-12-nn
                    10.12.0.11
                      NameNode
                Secondary NameNode
                         |
          +--------------+--------------+
          |              |              |
          v              v              v
    team-12-en      team-12-00      team-12-01
    10.12.0.10      10.12.0.12      10.12.0.13
      DataNode        DataNode        DataNode
```

---

## Используемое ПО

* Ubuntu 24.04
* Java 17
* Apache Hadoop 3.4.2

Hadoop устанавливается в:

```text
/opt/hadoop
```

Фактический каталог версии:

```text
/opt/hadoop-3.4.2
```

---

# 1. Автоматическое развёртывание

Основной скрипт:

```text
scripts/deploy_cluster.sh
```

Скрипт запускается на NameNode:

```text
team-12-nn
```

Перед запуском необходимо убедиться, что с NameNode доступно SSH-подключение к трём DataNode без ввода пароля:

```bash
ssh team-12-en hostname
ssh team-12-00 hostname
ssh team-12-01 hostname
```

Ожидаемый результат:

```text
team-12-en
team-12-00
team-12-01
```

После этого необходимо выполнить:

```bash
bash scripts/deploy_cluster.sh
```

Скрипт автоматически:

1. проверяет SSH-подключение к DataNode;
2. устанавливает Java 17 и Hadoop 3.4.2;
3. создаёт необходимые каталоги;
4. копирует конфигурационные файлы;
5. настраивает права доступа к HDFS-каталогам;
6. проверяет наличие метаданных NameNode;
7. при необходимости предлагает выполнить первоначальное форматирование NameNode;
8. запускает HDFS;
9. выполняет автоматическую проверку состояния кластера.

При повторном запуске существующий NameNode не форматируется автоматически.

---

# 2. Установка Hadoop

Для установки Hadoop используется:

```text
scripts/install_hadoop.sh
```

Скрипт устанавливает Java 17, скачивает Apache Hadoop 3.4.2, распаковывает его в `/opt` и создаёт символьную ссылку:

```text
/opt/hadoop -> /opt/hadoop-3.4.2
```

При необходимости скрипт можно запустить отдельно:

```bash
sudo bash scripts/install_hadoop.sh
```

При автоматическом развёртывании этот скрипт запускается `deploy_cluster.sh` на всех узлах.

---

# 3. Конфигурация Hadoop

Конфигурационные файлы находятся в каталоге:

```text
config/
```

Используются:

```text
core-site.xml
hdfs-site.xml
workers
hadoop-env.sh
```

### `core-site.xml`

Основная файловая система:

```text
hdfs://team-12-nn:9000
```

### `hdfs-site.xml`

Replication factor:

```text
3
```

NameNode:

```text
team-12-nn:9000
```

Web UI NameNode:

```text
team-12-nn:9870
```

Web UI Secondary NameNode:

```text
team-12-nn:9868
```

### `workers`

В список DataNode входят:

```text
team-12-en
team-12-00
team-12-01
```

---

# 4. Настройка конфигурации

Для применения конфигурации используется:

```text
scripts/configure_hadoop.sh
```

Запуск:

```bash
sudo bash scripts/configure_hadoop.sh
```

Скрипт копирует конфигурационные файлы в:

```text
/opt/hadoop/etc/hadoop/
```

и создаёт каталоги:

```text
/data/hdfs/namenode
/data/hdfs/datanode
```

Каталоги принадлежат пользователю `team`, от имени которого запускаются Hadoop-процессы.

При автоматическом развёртывании конфигурация применяется скриптом `deploy_cluster.sh`.

---

# 5. Форматирование NameNode

При первоначальном создании HDFS-кластера необходимо выполнить форматирование NameNode:

```bash
sudo bash scripts/format_namenode.sh
```

Скрипт содержит дополнительное подтверждение операции.

**Важно:** форматирование NameNode удаляет существующие метаданные HDFS.

Поэтому форматирование выполняется только при первоначальном создании нового кластера.

При обычном перезапуске или повторном развёртывании существующего кластера данный скрипт запускать нельзя.

`deploy_cluster.sh` проверяет наличие метаданных NameNode и не выполняет форматирование автоматически для уже существующего кластера.

---

# 6. Настройка SSH

Для запуска DataNode с NameNode используется SSH.

Необходимо обеспечить возможность подключения с:

```text
team-12-nn
```

к:

```text
team-12-en
team-12-00
team-12-01
```

без ввода пароля.

Проверка:

```bash
ssh team-12-en hostname
ssh team-12-00 hostname
ssh team-12-01 hostname
```

Ожидаемый результат:

```text
team-12-en
team-12-00
team-12-01
```

---

# 7. Запуск кластера

Запуск выполняется скриптом:

```text
scripts/start_cluster.sh
```

Команда:

```bash
bash scripts/start_cluster.sh
```

В результате должны быть запущены:

* NameNode;
* SecondaryNameNode;
* 3 DataNode.

Проверить процессы можно командой:

```bash
jps
```

---

# 8. Проверка кластера

Для автоматической проверки используется:

```text
scripts/check_cluster.sh
```

Запуск:

```bash
bash scripts/check_cluster.sh
```

Скрипт проверяет:

* версию Hadoop;
* запущенные Hadoop-процессы;
* состояние DataNode;
* количество работающих DataNode;
* состояние файловой системы HDFS;
* наличие отсутствующих и повреждённых блоков;
* наличие критических ошибок в логах.

Основная команда проверки DataNode:

```bash
hdfs dfsadmin -report
```

В корректно работающем кластере должно быть:

```text
Live datanodes (3)
```

и:

```text
Dead datanodes (0)
```

---

# 9. Проверка через NameNode Web UI

NameNode предоставляет Web UI:

```text
http://team-12-nn:9870
```

В интерфейсе необходимо проверить состояние кластера и убедиться, что:

* присутствуют 3 Live DataNodes;
* отсутствуют Dead DataNodes;
* нет проблем с состоянием узлов.

Это соответствует проверке состояния кластера из задания.

---

# 10. Проверка файловой системы

Дополнительная проверка выполняется:

```bash
hdfs fsck / -files -blocks -locations
```

Для исправного кластера:

```text
Status: HEALTHY
```

Не должно быть:

```text
Missing blocks
Corrupt blocks
Under-replicated blocks
```

Replication factor установлен равным:

```text
3
```

Тестовый файл:

```text
/user/team/test/hdfs-test.txt
```

имеет три реплики, по одной на каждом DataNode.

---

# 11. Остановка кластера

Для остановки используется:

```text
scripts/stop_cluster.sh
```

Команда:

```bash
bash scripts/stop_cluster.sh
```

После остановки можно проверить состояние процессов:

```bash
jps
```

---

# 12. Структура репозитория

```text
hdfs-homework-1/
│
├── README.md
│
├── config/
│   ├── core-site.xml
│   ├── hdfs-site.xml
│   ├── workers
│   └── hadoop-env.sh
│
└── scripts/
    ├── install_hadoop.sh
    ├── configure_hadoop.sh
    ├── format_namenode.sh
    ├── deploy_cluster.sh
    ├── start_cluster.sh
    ├── stop_cluster.sh
    └── check_cluster.sh
```

---

# 13. Результат проверки

После развёртывания корректное состояние кластера определяется следующими параметрами:

```text
1 × NameNode
1 × Secondary NameNode
3 × DataNode
```

Проверка выполняется с помощью:

```bash
hdfs dfsadmin -report
```

```bash
hdfs fsck / -files -blocks -locations
```

и:

```bash
bash scripts/check_cluster.sh
```

Для исправного кластера ожидается:

```text
Live datanodes (3)
Dead datanodes (0)
Under replicated blocks: 0
Missing blocks: 0
Corrupt blocks: 0
Status: HEALTHY
No critical errors found.
```

Также состояние кластера можно проверить через NameNode Web UI:

```text
http://team-12-nn:9870
```
