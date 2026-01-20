def label = "jenkins-git-agent_1_0_a"

podTemplate(
  cloud: "kubernetes",
  label: label,
  idleMinutes: 02,
  nodeUsageMode: "EXCLUSIVE",
  yaml: """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-admin
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock

  containers:
  - name: build
    image: docker:27.4.1-cli
    command: ['cat']
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: jnlp
    image: jenkins/inbound-agent:latest
"""
) {
  node(label) {

    container('build') {

      stage("Checkout") {
        sh '''
          apk add --no-cache git
          git clone https://github.com/aswarda/sample-app.git
        '''
      }

      stage("Docker Build") {
        sh '''
          docker version
          docker build -t sample-app:latest sample-app
          docker run --rm sample-app:latest
        '''
      }
    }
  }
}
