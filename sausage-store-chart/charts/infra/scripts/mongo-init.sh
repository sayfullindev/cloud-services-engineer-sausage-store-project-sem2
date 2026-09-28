#!/bin/sh
# Создаёт базу и пользователя для отчётов
# Все креды приходят переменными окружения из секрета mongodb-secret.
set -e

URI="mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$MONGO_HOST/admin"

echo "waiting for mongodb at $MONGO_HOST ..."
until mongosh "$URI" --quiet --eval 'db.runCommand({ping:1})' >/dev/null 2>&1; do
  sleep 2
done
echo "mongodb is up"

mongosh "$URI" --quiet --eval '
  const target = db.getSiblingDB(process.env.MONGO_REPORT_DATABASE);
  const user = process.env.MONGO_REPORT_USERNAME;
  if (target.getUser(user)) {
    print("user " + user + " already exists, skipping");
  } else {
    target.createUser({
      user: user,
      pwd: process.env.MONGO_REPORT_PASSWORD,
      roles: [ { role: "readWrite", db: process.env.MONGO_REPORT_DATABASE } ]
    });
    print("user " + user + " created");
  }
'
