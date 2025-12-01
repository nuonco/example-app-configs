---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-init
  namespace: temporal
  labels:
    app: temporal-init
spec:
  replicas: 1
  selector:
    matchLabels:
      app: temporal-init
  template:
    metadata:
      labels:
        app: temporal-init
    spec:
      containers:
        - name: temporal-init
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: [ "tail", "-f", "/dev/null" ]
          env:
          - name: SQL_HOST
            value: "{{ .Values.db.host }}"
          - name: SQL_PORT
            value: "{{ .Values.db.port }}"
          - name: SQL_USER
            value: "{{ .Values.db.username }}"
          - name: SQL_PLUGIN
            value: "{{ .Values.temporal.sql.plugin }}"
          - name: SQL_PASSWORD
            valueFrom:
              secretKeyRef:
                name: temporal-db
                key: password
          - name: ADMIN_DB_USERNAME
            valueFrom:
              secretKeyRef:
                name: temporal-db
                key: username
          - name: TEMPORAL_DB_PW
            valueFrom:
              secretKeyRef:
                name: temporal-temporal-db-pw
                key: value
          - name: TEMPORAL_VISIBILITY_DB_PW
            valueFrom:
              secretKeyRef:
                name: temporal-visibility-db-pw
                key: value
          volumeMounts:
          - name: init-config
            mountPath: "/var/init-config"
      volumes:
        - name: init-config
          configMap:
            name: temporal-init
            items:
            - key: init_temporal_db.sh
              path: init_temporal_db.sh
            - key: init_visibility_db.sh
              path: init_visibility_db.sh
      nodeSelector:
        pool.nuon.co: "temporal"
      tolerations:
        - key: "pool.nuon.co"
          operator: "Equal"
          value: "temporal"
          effect: "NoSchedule"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: temporal-psql
  namespace: temporal
  labels:
    app: temporal-psql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: temporal-psql
  template:
    metadata:
      labels:
        app: temporal-psql
    spec:
      containers:
        - name: temporal-psql
          image: "postgres:15-alpine3.20"
          command: [ "tail", "-f", "/dev/null" ]
          env:
          - name: PGHOST
            value: "{{ .Values.db.host }}"
          - name: PGPORT
            value: "{{ .Values.db.port }}"
          - name: PGUSER
            value: "{{ .Values.db.username }}"
          - name: PGPASSWORD
            valueFrom:
              secretKeyRef:
                name: temporal-db
                key: password
          - name: ADMIN_DB_USERNAME
            valueFrom:
              secretKeyRef:
                name: temporal-db
                key: username
          - name: TEMPORAL_DB_PW
            valueFrom:
              secretKeyRef:
                name: temporal-temporal-db-pw
                key: value
          - name: TEMPORAL_VISIBILITY_DB_PW
            valueFrom:
              secretKeyRef:
                name: temporal-visibility-db-pw
                key: value
          volumeMounts:
          - name: init-config
            mountPath: "/var/init-config"
      volumes:
        - name: init-config
          configMap:
            name: temporal-init
            items:
            - key: create_db_users.sh
              path: create_db_users.sh
      nodeSelector:
        pool.nuon.co: "temporal"
      tolerations:
        - key: "pool.nuon.co"
          operator: "Equal"
          value: "temporal"
          effect: "NoSchedule"
