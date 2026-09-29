# Sausage Store

Интернет-магазин сосисок, проект второго семестра. Приложение собирается в GitHub Actions, чарт хранится в Nexus, деплой в Kubernetes.

Адрес: https://front-gabella.2sem.students-projects.ru

## Состав

- `frontend` - Angular, отдаётся через nginx. nginx же проксирует `/api` на бэкенд.
- `backend` - Java 17, Spring Boot. Работает с PostgreSQL и MongoDB.
- `backend-report` - Go, по расписанию пишет отчёты в MongoDB.
- PostgreSQL 16 и MongoDB 7 поднимаются в кластере из чарта `infra`.

## Структура репозитория

```
.github/workflows/deploy.yaml      CI/CD
backend/src/main/resources/db/migration   миграции Flyway V001-V004
sausage-store-chart/               общий Helm-чарт
  charts/backend                   Deployment, Service, ConfigMap, Secret, VPA
  charts/backend-report            Deployment, ConfigMap, Secret, HPA
  charts/frontend                  Deployment, Service, ConfigMap с nginx.conf, Ingress
  charts/infra                     PostgreSQL, MongoDB, Job для создания пользователя Mongo
```

## CI/CD

Пайплайн запускается на push в main или вручную. Три джобы:

1. Сборка образов и пуш в Docker Hub. Каждый образ получает два тега: `latest` и хеш коммита.
2. `helm package` с версией `0.1.<номер запуска>` и загрузка архива в Nexus.
3. Деплой чарта из Nexus через `helm upgrade --install` с `--wait`. Образы подставляются по хешу коммита, поэтому поды пересоздаются на каждом деплое.

Нужные секреты: `DOCKER_USER`, `DOCKER_PASSWORD`, `NEXUS_HELM_REPO`, `NEXUS_HELM_REPO_USER`, `NEXUS_HELM_REPO_PASSWORD`, `KUBE_CONFIG`.

## Nexus
В Nexus создан репозиторий типа helm(hosted) с именем sausage-store-gabella с параметром Deployment policy: "Allow redeploy".

## Ручной деплой

```bash
helm repo add nexus https://nexus.cloud-services-engineer.education-services.ru/repository/sausage-store-gabella \
  --username <user> --password <password>
helm repo update
helm upgrade --install sausage-store nexus/sausage-store \
  --namespace <namespace> --history-max 3 --wait --timeout 10m
```

Проверка чарта без установки:

```bash
helm lint sausage-store-chart
helm template sausage-store sausage-store-chart | kubectl apply --dry-run=server -f -
```

## Решения
Квота неймспейса небольшая. Под неё подобраны ресурсы всех компонентов, отсюда часть решений ниже.

- Фронтенд обновляется через Recreate. Helm обновляет все деплойменты одновременно, и если у бэкенда и фронтенда во время RollingUpdate будет по лишнему поду, запрос памяти выйдет за квоту.
- `--history-max 3` при деплое. Helm хранит каждую ревизию в отдельном секрете, а секретов в квоте 10.
- MongoDB запускается с `--wiredTigerCacheSizeGB 0.25`. По умолчанию кэш занимает минимум 256MB, и под с лимитом памяти падал бы по OOM.
- Пользователя `reports` в MongoDB создаёт Job с хуком `post-install,post-upgrade`. Скрипт ждёт готовности базы и не падает, если пользователь уже есть. Политика `before-hook-creation` удаляет старый Job перед новым, иначе повторный upgrade упадёт на неизменяемом `spec`.
- У бэкенда стоят аннотации с хешем ConfigMap и Secret. При смене конфигурации поды перезапускаются сами.
- VPA работает в режиме `Off`, только собирает рекомендации.