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
  volumes:
  - name: docker-config
    emptyDir: {}
  - name: workspace
    emptyDir: {}
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://jenkins.jenkins.svc.cluster.local:8080/"
  - name: docker-dind
    image: docker:27.4.1-dind
    privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR 
      value: ""                 
    volumeMounts:
    - name: docker-config
      mountPath: /certs/client
    - name: workspace
      mountPath: /workspace
  - name: docker-cli
    image: docker:27.4.1-alpine3.21
    env:
    - name: DOCKER_HOST
      value: tcp://localhost:2376
    - name: DOCKER_TLS_CERTDIR  # ← FIXED: Proper YAML structure
      value: ""
    volumeMounts:
    - name: docker-config
      mountPath: /certs/client
    - name: workspace
      mountPath: /workspace
    command: ['cat']
    tty: true
  - name: git
    image: alpine/git:latest
    command: ['cat']
    tty: true
    env:
    - name: GIT_TOKEN
      valueFrom:
        secretKeyRef:
          name: git-token
          key: token
"""
) {
    node(label) {
        container('git') {
            stage('Checkout') {
                sh '''
                    git config --global url."https://${GIT_TOKEN}@github.com/".insteadOf "https://github.com/"
                    git clone https://github.com/aswarda/sample-app.git /workspace/sample-app
                '''
            }
        }
        
        container('docker-cli') {
            stage('Docker Build') {
                sh '''
                    docker info
                    cd /workspace/sample-app
                    docker build -t sample-app:latest -f Dockerfile .
                    docker run --rm sample-app:latest
                '''
            }
        }
    }
}
