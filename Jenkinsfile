pipeline {

    agent any

    stages {
        stage('Git Checkout') {
            steps {
                echo 'Checkout Remote Repository'
                git branch: "${env.BRANCH_NAME}",
                url: 'https://github.com/dukcode/cicd.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Build With gradlew'
                sh '''
                    ./gradlew clean build
                '''
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                echo 'Build & Push Docker Image'
                withCredentials([usernamePassword(
                        credentialsId: 'DOCKER_HUB_CREDENTIAL',
                        usernameVariable: 'DOCKER_HUB_ID',
                        passwordVariable: 'DOCKER_HUB_PW')]) {

                    script {
                        docker.withRegistry('https://registry.hub.docker.com',
                                            'DOCKER_HUB_CREDENTIAL') {
                        app = docker.build("${DOCKER_HUB_ID}/cicd-test")
                        app.push("${env.BUILD_ID}")
                        app.push('latest')
                        }
                    }
                    sh """
                        docker rmi \$(docker images -q \
                        --filter \"before=${DOCKER_HUB_ID}/cicd-test:latest\" \
                        registry.hub.docker.com/${DOCKER_HUB_ID}/cicd-test)
                    """
                }
            }
        }

        stage('Deploy to Server') {
            steps {
                echo 'Deploy to Server'
                withCredentials([
                    usernamePassword(credentialsId: 'DOCKER_HUB_CREDENTIAL',
                                        usernameVariable: 'DOCKER_HUB_ID',
                                        passwordVariable: 'DOCKER_HUB_PW'),
                    sshUserPrivateKey(credentialsId: 'DEV_SSH',
                                        keyFileVariable: 'KEY_FILE',
                                        passphraseVariable: 'PW',
                                        usernameVariable: 'USERNAME'),
                    string(credentialsId: 'DEV_SSH_HOST', variable: 'HOST'),
                    string(credentialsId: 'DEV_SSH_PORT', variable: 'PORT')]) {

                    script {
                        def remote = [:]
                        remote.name = 'cicd_test'
                        remote.host = "${HOST}"
                        remote.user = "${USERNAME}"
                        remote.password = "${PW}"
                        remote.port = "${PORT}" as Integer
                        remote.allowAnyHosts = true

                        sshCommand remote: remote, command: """
                            docker pull ${DOCKER_HUB_ID}/cicd-test:latest
                        """
                        sshCommand remote: remote, command: 'docker rm -f springboot'
                        sshCommand remote: remote, command: """
                            docker run -d --name springboot \\
                            -p 8080:8080 -e \"SPRING_PROFILES_ACTIVE=dev\" \\
                            ${DOCKER_HUB_ID}/cicd-test:latest
                        """
                    }
                }
            }
        }

    }
}