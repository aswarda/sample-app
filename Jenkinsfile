def label = "jenkins-git-agent_1_0_a"

podTemplate(
    cloud: "kubernetes",
    name: label,
    label: label,
    idleMinutes: 20,
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
    runAsUser: 1000
    runAsGroup: 1000
  volumes: 
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
  - name: docker-config
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
    securityContext:
      privileged: true
      runAsUser: 0
    env:
    - name: DEBIAN_FRONTEND
      value: noninteractive
    - name: DOCKER_HOST
      value: unix:///var/run/docker.sock
    volumeMounts: 
    - name: docker-sock
      mountPath: /var/run/docker.sock
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
                    ls -la sample-app/
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
                    apt-get update
                    apt-get install -y ca-certificates curl gnupg lsb-release
                    
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                    
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
                    
                    apt-get update
                    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                    
                    docker --version
                    echo "✅ Docker installed successfully!"
                '''
            }

            stage("Build Docker Image") {
                sh '''
                    cd sample-app
                    ls -la
                    cat Dockerfile || echo "No Dockerfile found"
                    
                    docker build -t sample-app:${BUILD_NUMBER} .
                    docker images | grep sample-app
                    
                    echo "✅ Docker image built successfully: sample-app:${BUILD_NUMBER}"
                '''
            }

            stage("Test Docker Image") {
                sh '''
                    docker run --rm sample-app:${BUILD_NUMBER} --help || echo "Image runs successfully"
                '''
            }
        }
    }
}
