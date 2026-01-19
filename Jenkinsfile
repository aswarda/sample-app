def label = "jenkins-git-agent_1_0_a"

podTemplate(
    cloud: "kubernetes",
    name: label,
    label: label,
    idleMinutes: 60,
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

  - name: jnlp
    image: jenkins/inbound-agent:latest

  - name: ubuntu
    image: ubuntu:22.04
    command: ['cat']
    tty: true
    env:
    - name: DEBIAN_FRONTEND
      value: noninteractive
"""
) {

    node(label) {

        /* ---------------- BUILD CONTAINER ---------------- */
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

        /* ---------------- UBUNTU CONTAINER ---------------- */
        container('ubuntu') {

            stage('Build (Ubuntu)') {
                sh '''
                  apt-get update
                  apt-get install -y curl make gcc
                  echo "Running complex build operations"
                '''
            }

            stage('Test (Ubuntu)') {
                sh '''
                  echo "Running tests with Ubuntu tools"
                '''
            }
        }
    }
}
