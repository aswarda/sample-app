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
  containers:
  - name: build
    image: alpine/git:latest
    command:
    - cat
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
    command:
    - cat
    tty: true
    env:
    - name: DEBIAN_FRONTEND
      value: noninteractive
"""
) {
    node(label) {
        // KEEP ALL EXISTING STAGES IN BUILD CONTAINER
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
                    cat sample-app/Jenkinsfile
                '''
            }

            stage("Test") {
                sh '''
                    echo "Running tests inside Kubernetes agent pod"
                '''
            }
        }

        // NEW UBUNTU CONTAINER STAGES
        container('ubuntu') {
            stage("Install Docker") {
                sh '''
                    apt-get update
                    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
                    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
                    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
                    apt-get update
                    apt-get install -y docker-ce docker-ce-cli containerd.io
                    docker --version
                    echo "Docker installed successfully!"
                '''
            }

            stage("Docker Build (Ubuntu)") {
                sh '''
                    cd sample-app
                    docker build -t sample-app:latest -f Dockerfile .
                    docker run --rm sample-app:latest echo "Docker build successful!"
                '''
            }
        }
    }
}
