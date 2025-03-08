# Maven
## Maven Pipeline sử dụng trong Jenkins Container

```groovy
    pipeline {
        agent {
            docker {
                image 'maven:3.8.6-openjdk-11'  // Chạy Maven trong container
            }
        }
        stages {
            stage('Clone Source Code') {
                steps {
                    git 'https://github.com/example/java-maven-app.git'
                }
            }
            stage('Build & Package') {
                steps {
                    sh 'mvn clean package'
                }
            }
        }
    }
```

## Maven Container

``` yaml
  apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: maven
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: maven
      template:
        metadata:
          labels:
            app: maven
        spec:
          containers:
          - name: maven
            image: maven:3.8.6-openjdk-11
            command: ["/bin/sh", "-c", "while true; do sleep 30; done;"]
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: maven-service
    spec:
      type: ClusterIP
      ports:
      - port: 8080
        targetPort: 8080
      selector:
        app: maven
```