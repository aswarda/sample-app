def label = "jenkins-git-agent_1_0_a"

podTemplate(
    cloud: "kubernetes",
    name: label,
    label: label,
    idleMinutes: 2,
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
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: Socket 
  - name: docker-workspace
    emptyDir: {}
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
    image: docker:27.4.1-alpine3.21  # ← Docker CLI only, NO DinD
    command: ['cat']  # ← Keep alive
    tty: true
    env:
    - name: DOCKER_HOST
      value: "unix:///var/run/docker.sock"
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    - name: docker-workspace
      mountPath: /workspace
"""
) {
    node(label) {
        container('build') {
            stage("Checkout Code") {
                sh '''
                    git config --global url."https://${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"
                    git clone https://github.com/aswarda/sample-app.git
                '''
            }
        }

        container('ubuntu') {
            stage("Install Docker") {
                sh '''
                    apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                    apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    docker --version
                '''
            }
        }

        container('docker') {
            stage('Docker Build') {
                sh '''
                    cp -r /home/jenkins/agent/workspace/sample-app /workspace/
                    cd /workspace/sample-app
                    docker info
                    docker build -t sample-app:latest -f Dockerfile .
                    docker run --rm sample-app:latest
                '''
            }
        }
    }
}
