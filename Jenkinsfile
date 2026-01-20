def label = "jenkins-git-agent_1_0_a"

podTemplate(
    cloud: "kubernetes",
    name: label,
    label: label,
    idleMinutes: 02,
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
  volumes:  # ← ADD THIS
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
    volumeMounts:  # ← ADD THIS
    - name: docker-sock
      mountPath: /var/run/docker.sock
  - name: docker      # ← REPLACED ubuntu
    image: docker:27.4.1-dind-alpine3.21
    privileged: true   # Docker daemon needs this
    command: ['dockerd']
    env:
    - name: DOCKER_TLS_CERTDIR
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
                    git config --global url."https://${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"
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

        container('ubuntu') {
            stage("Install Docker") {
                sh '''
                    # Install prerequisites
                    apt-get update
                    apt-get install -y ca-certificates curl gnupg lsb-release
                    
                    # Add Docker GPG key (modern method - no deprecated apt-key)
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                    
                    # Add Docker repository (manual echo - no add-apt-repository needed)
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                    
                    # Install Docker
                    apt-get update
                    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    
                    # Verify
                    docker --version
                    echo "✅ Docker installed successfully!"
                '''
            }
            
        container('docker') {
            stage('Docker Build') {
                sh '''
                    docker build -t sample-app:latest -f sample-app/Dockerfile .
                    docker run --rm sample-app:latest
                '''
                }
            }
        }
    }
}
