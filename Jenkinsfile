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
    }
}