def label = "jenkins-git-agent_1_0_a"

podTemplate(
    cloud: "kubernetes",
    name: label,
    label: label,
    idleMinutes: 05,
    nodeUsageMode: "EXCLUSIVE",
    yaml: """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: slave
spec:
  serviceAccountName: jenkins-admin
  securityContext:
    fsGroup: 1000
    runAsUser: 0
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
  containers:
  - name: build
    image: alpine/git:latest
    command: ['cat']
    tty: true
    env:
    - name: GIT_TOKEN
      valueFrom:
        secretKeyRef:
          name: git-token
          key: token
    - name: JENKINS_URL
      value: "http://jenkins.jenkins.svc.cluster.local:8080/"
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://jenkins.jenkins.svc.cluster.local:8080/"
  - name: ubuntu
    image: ubuntu:22.04
    command: ['cat']
    tty: true
    env:
    - name: DEBIAN_FRONTEND
      value: noninteractive
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: docker
    image: docker:24-dind
    securityContext:
      privileged: true
    env:
    - name: ACR_USERNAME
      valueFrom:
        secretKeyRef:
          name: acr-creds
          key: username
    - name: ACR_PASSWORD
      valueFrom:
        secretKeyRef:
          name: acr-creds
          key: password
  - name: snyk
    image: snyk/snyk:docker
    command: ['cat']
    tty: true
    env:
    - name: SNYK_TOKEN
      valueFrom:
        secretKeyRef:
          name: snyk-token
          key: token
    - name: SNYK_ORG
      valueFrom:
        secretKeyRef:
          name: snyk-token
          key: org_id
    - name: SNYK_REGISTRY_USERNAME
      valueFrom:
        secretKeyRef:
          name: acr-creds
          key: username
    - name: SNYK_REGISTRY_PASSWORD
      valueFrom:
        secretKeyRef:
          name: acr-creds
          key: password
"""
) {
    node(label) {
        container('build') {
            stage("Prepare Workspace") {
                ws('/home/jenkins/agent/workspace') {
                    cleanWs()
                }
            }

            stage("Checkout Code") {
                sh '''
                    git clone https://github.com/aswarda/sample-app.git
                '''
            }

            stage("Build") {
                sh '''
                    echo "Running build inside Kubernetes agent pod"
                    ls -la sample-app
                '''
            }

            stage("Test") {
                sh '''
                    echo "Running tests inside Kubernetes agent pod"
                '''
            }
        }

        container('docker') {
            stage("Install Docker") {
                sh '''
                    # Verify
                    docker --version

                    echo "🔐 Logging in to ACR"
                    echo $ACR_PASSWORD | docker login aswardacr2026.azurecr.io \
                      -u $ACR_USERNAME --password-stdin

                    echo "🐳 Building image"
                    docker build -t sample-app:latest ./sample-app

                    echo "🏷️ Tagging image"
                    docker tag sample-app:latest \
                      aswardacr2026.azurecr.io/sample-app:${BUILD_NUMBER}

                    echo "📤 Pushing image"
                    docker push aswardacr2026.azurecr.io/sample-app:${BUILD_NUMBER}

                    docker images
                '''
            }
        }
        container('snyk') {
            stage("Install Snyk") {
                sh '''
                    # Verify
                    snyk --version
                    echo "✅ Snyk installed successfully!"
                    snyk auth $SNYK_TOKEN
                    snyk config set org=$SNYK_ORG
                    snyk code test ./sample-app --include-ignores
                    snyk container test aswardacr2026.azurecr.io/sample-app:${BUILD_NUMBER} || true

                '''
            }
        }
    }
}
