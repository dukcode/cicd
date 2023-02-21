pipeline {

    agent any

    environment {
        GPG_SECRET_KEY = credentials('GPG_SECRET_KEY')

        // PORT
        EXTERNAL_PORT_BLUE = credentials("EXTERNAL_PORT_BLUE")
        EXTERNAL_PORT_GREEN = credentials("EXTERNAL_PORT_GREEN")
    }

    stages {
        stage('Set Variables') {
            steps {
                echo 'Set Variables'
                script {
                    // OPERATION_ENV
                    OPERATION_ENV = env.BRANCH_NAME.equals('main') ? 'prod' : 'dev'

                    // DOCKER
                    DOCKER_IMAGE_NAME = env.BRANCH_NAME.equals('main') ? 'prod-cicd-test' : 'dev-cicd-test'

                    // SSH
                    SSH_CREDENTIAL_ID = env.BRANCH_NAME.equals('main') ? 'PROD_SSH' : 'DEV_SSH'
                    SSH_HOST_CREDENTIAL_ID = env.BRANCH_NAME.equals('main') ? 'PROD_SSH_HOST' : 'DEV_SSH_HOST'
                    SSH_PORT_CREDENTIAL_ID = env.BRANCH_NAME.equals('main') ? 'PROD_SSH_PORT' : 'DEV_SSH_PORT'

                }

            }
        }

        stage('Git Checkout') {
            steps {
                echo 'Checkout Remote Repository'
                git branch: "${env.BRANCH_NAME}",
                url: 'https://github.com/dukcode/cicd.git'
            }
        }

        stage('Git Secret Reveal') {
            steps {
                echo 'Git Secret Reveal'
                sh """
                    gpg --batch --import ${GPG_SECRET_KEY}
                    git secret reveal -f
                """
            }
        }

        stage('Parse Interal Port') {
            steps {
                script {
                    INTERNAL_PORT = sh(script: "yq e '.server.port' ./src/main/resources/application-${OPERATION_ENV}.yml", returnStdout: true).trim();
                }
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
                        app = docker.build("${DOCKER_HUB_ID}/${DOCKER_IMAGE_NAME}")
                        app.push("${env.BUILD_ID}")
                        app.push('latest')
                        }
                    }
                    sh(script: """
                        docker rmi \$(docker images -q \
                        --filter \"before=${DOCKER_HUB_ID}/${DOCKER_IMAGE_NAME}:latest\" \
                        registry.hub.docker.com/${DOCKER_HUB_ID}/${DOCKER_IMAGE_NAME})
                    """, returnStatus: true)
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
                    sshUserPrivateKey(credentialsId: "${SSH_CREDENTIAL_ID}",
                                        keyFileVariable: 'KEY_FILE',
                                        passphraseVariable: 'PW',
                                        usernameVariable: 'USERNAME'),
                    string(credentialsId: "${SSH_HOST_CREDENTIAL_ID}", variable: 'HOST'),
                    string(credentialsId: "${SSH_PORT_CREDENTIAL_ID}", variable: 'PORT')]) {

                    script {
                        def remote = [:]
                        remote.name = "${OPERATION_ENV}"
                        remote.host = "${HOST}"
                        remote.user = "${USERNAME}"
                        remote.password = "${PW}"
                        remote.port = "${PORT}" as Integer
                        remote.allowAnyHosts = true

                        sshCommand remote: remote, command: """
                            docker pull ${DOCKER_HUB_ID}/${DOCKER_IMAGE_NAME}:latest
                        """
                        sshPut remote: remote, from: './deploy.sh', into: '.'
                        sshPut remote: remote, from: './nginx.conf', into: '.'

                        sshCommand remote: remote, command: """
                            export OPERATION_ENV=${OPERATION_ENV} &&\\
                            export INTERNAL_PORT=${INTERNAL_PORT} &&\\
                            export EXTERNAL_PORT_GREEN=${EXTERNAL_PORT_GREEN} &&\\
                            export EXTERNAL_PORT_BLUE=${EXTERNAL_PORT_BLUE} &&\\
                            export DOCKER_IMAGE_NAME=${DOCKER_HUB_ID}/${DOCKER_IMAGE_NAME} &&\\
                            chmod +x deploy.sh &&\\
                            ./deploy.sh
                            """
                    }
                }
            }
        }

    }
}