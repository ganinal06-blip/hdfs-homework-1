# Домашнее задание №1 — развертывание HDFS-кластера

## Цель

Необходимо развернуть кластер HDFS, включающий:

* 3 DataNode;
* NameNode;
* Secondary NameNode.

После развертывания необходимо проверить целостность кластера и убедиться, что все 3 DataNode работают.

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
          +------------+------------+
          |            |            |
          v            v            v
    team-12-en    team-12-00    team-12-01
    10.12.0.10    10.12.0.12    10.12.0.13
     DataNode      DataNode       DataNode
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

# 1. Установка Hadoop

Скрипт:

```text
scripts/install_hadoop.sh
```

Скрипт устанавливает Java 17, скачивает Apache Hadoop 3.4.2, распаковывает его в `/opt` и создаёт символьную ссылку:

```text
/opt/hadoop -> /opt/hadoop-3.4.2
```

Запуск:

```bash
sudo bash scripts/install_hadoop.sh
```

Скрипт необходимо выполнить на всех узлах кластера.

---

# 2. Конфигурация Hadoop

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

# 3. Настройка конфигурации

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

---

# 4. Форматирование NameNode

При первоначальном создании HDFS-кластера необходимо выполнить форматирование NameNode:

```bash
sudo bash scripts/format_namenode.sh
```

Скрипт содержит дополнительное подтверждение операции.

**Важно:** форматирование NameNode удаляет существующие метаданные HDFS и поэтому выполняется только при первоначальном создании кластера.

При обычном перезапуске кластера данный скрипт запускать нельзя.

---

# 5. Настройка SSH

Для запуска DataNode с NameNode используется SSH.

Необходимо обеспечить возможность подключения с `team-12-nn` к:

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

# 6. Запуск кластера

Запуск выполняется скриптом:

```text
scripts/start_cluster.sh
```

Команда:

```bash
sudo bash scripts/start_cluster.sh
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

# 7. Проверка кластера

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

# 8. Проверка через NameNode Web UI

NameNode предоставляет Web UI по адресу:

```text
http://team-12-nn:9870
```

В интерфейсе необходимо проверить состояние кластера и убедиться, что:

* присутствуют 3 Live DataNodes;
* отсутствуют Dead DataNodes;
* нет деградировавших узлов.

Это соответствует первому варианту проверки из задания.

---

# 9. Проверка файловой системы

Дополнительная проверка выполняется:

```bash
hdfs fsck / -files -blocks -locations
```

Для исправного кластера не должно быть:

```text
MISSING BLOCKS
CORRUPT BLOCKS
```

Replication factor установлен равным:

```text
3
```

что позволяет хранить три копии блоков на трёх DataNode.

---

# 10. Остановка кластера

Для остановки используется:

```text
scripts/stop_cluster.sh
```

Запуск:

```bash
sudo bash scripts/stop_cluster.sh
```

После остановки можно проверить отсутствие Hadoop-процессов командой:

```bash
jps
```

---

# 11. Структура репозитория

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
    ├── start_cluster.sh
    ├── stop_cluster.sh
    └── check_cluster.sh
```

---

# 12. Результат

В результате был развернут HDFS-кластер со следующими компонентами:

```text
1 × NameNode
1 × Secondary NameNode
3 × DataNode
```

Проверка состояния кластера выполняется через NameNode Web UI, `hdfs dfsadmin -report` и `hdfs fsck`.

Кластер считается корректно работающим, если все 3 DataNode находятся в состоянии Live, отсутствуют Dead DataNodes, а файловая система не содержит отсутствующих или повреждённых блоков.

