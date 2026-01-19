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
    - name: JENKINS_URL
      value: "http://jenkins.jenkins.svc.cluster.local:8080/"  # FIXED: Use proper service DNS
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
    - name: JENKINS_URL
      value: "http://jenkins.jenkins.svc.cluster.local:8080/"  # ADD: JNLP needs it too
"""
) {
    // rest of pipeline unchanged
}
