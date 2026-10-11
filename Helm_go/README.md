# Go application

Helm chart с обычными YAML-манифестами. Все настройки записаны прямо в файлах.
Файлов values.yaml, _helpers.tpl и шаблонных выражений нет.

## Установка через Helm

Из каталога, содержащего Helm_go:

```bash
helm lint ./Helm_go
helm template goapp ./Helm_go
helm upgrade --install goapp ./Helm_go --namespace default --wait --timeout 5m
```

Или установка тех же ресурсов напрямую:

```bash
kubectl apply -n default -f Helm_go/templates/
kubectl rollout status -n default deployment/goapp
```

Используй один способ управления ресурсами. Имена ресурсов фиксированы: goapp.
Другой release name не изменит имена, поэтому в одном namespace можно установить
только один экземпляр. Для установки в другой namespace поменяй default в командах.

## Настройки

- Deployment: образ ghcr.io/matthew62s/diplom_sorokvashin_dos35:latest,
  политика IfNotPresent, порт контейнера 8080, HTTP-пробы на /.
- Service: NodePort, порт сервиса 8080. Kubernetes назначает nodePort автоматически.
- ServiceAccount: goapp, automountServiceAccountToken включён как в исходном chart.
- HPA: 2–6 реплик, целевая загрузка CPU 80%.
- CPU request: 100m. Добавлен для работы HPA; подбери по измерениям приложения.
  Поле replicas в Deployment опущено, поскольку числом реплик управляет HPA.
- Ingress отсутствует: в исходном values.yaml он был выключен.

Для HPA нужен доступный API resource metrics (обычно metrics-server).
Secret ghcr-cred должен существовать в том же namespace, где запускается приложение.
Тег latest оставлен из исходного chart: проверь, что он опубликован и доступен.
Чтобы изменить настройки, редактируй deployment.yaml, service.yaml или hpa.yaml напрямую.

## Проверка

```bash
kubectl get pods,svc,hpa -n default
kubectl get svc goapp -n default -o jsonpath='{.spec.ports[0].nodePort}'
```

Приложение доступно по адресу http://IP-узла:NODEPORT, если сеть и firewall
разрешают подключения к назначенному порту.

Необязательный тест вынесен за пределы templates, чтобы он не запускался
при каждом применении манифестов и его Pod не попадал под selector сервиса:

```bash
kubectl delete pod goapp-test-connection -n default --ignore-not-found
kubectl apply -n default -f Helm_go/tests/test-connection.yaml
kubectl logs -n default -f goapp-test-connection
kubectl get pod goapp-test-connection -n default
kubectl delete pod goapp-test-connection -n default
```

Успешный тест завершается со статусом Completed. Это отдельный Pod, а не Helm hook.

## Перенос существующей установки

Раньше имена и selector содержали имя Helm release. Здесь они фиксированы.
Перед обновлением существующего release проверь вывод helm template и сравни его
с установленными ресурсами. Изменение имени создаёт новый ресурс; изменение
spec.selector существующего Deployment Kubernetes не разрешает.
Команда установки выше рассчитана на новую установку.

## Проверено при подготовке

YAML-синтаксис, отсутствие шаблонов и согласованность selector, портов,
ServiceAccount и HPA. Установка в кластер и команды Helm не запускались.
