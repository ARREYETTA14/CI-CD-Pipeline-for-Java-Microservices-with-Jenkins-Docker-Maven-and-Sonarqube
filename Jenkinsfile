// pipeline {
//     agent any

//     tools {
//         maven 'maven_latest'  // This name must match the one in Global Tool Configuration
//     }

//     environment {
//         SONAR_TOKEN = credentials('sonar-token')  // Jenkins credentials ID
//         AWS_REGION = 'sa-east-1'
//         AWS_ACCOUNT_ID = '211125453684'
//         ECR_REPO_NAME = 'hello-world'
//         EKS_CLUSTER_NAME = 'eks'
//         SONAR_PROJECT_KEY = 'hello-world'
//         SONARQUBE_ENV_NAME = 'SonarQube Scanner'  // This must match Jenkins Sonar config name!
//     }

//     stages {
//         stage('Checkout') {
//             steps {
//                 git 'git@github.com:ARREYETTA14/CI-CD-Pipeline-for-Java-Microservices-with-Jenkins-Docker-Maven-and-Sonarqube.git'
//             }
//         }

//         stage('Build and SonarQube Analysis') {
//             steps {
//                 script {
//                     withSonarQubeEnv("${SONARQUBE_ENV_NAME}") {
//                         sh """
//                             mvn clean verify sonar:sonar \
//                             -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
//                             -Dsonar.login=${SONAR_TOKEN}
//                         """
//                     }
//                 }
//             }
//         }

//         stage('Quality Gate') {
//             steps {
//                 timeout(time: 2, unit: 'MINUTES') {
//                     script {
//                         def qg = waitForQualityGate()
//                         if (qg.status != 'OK') {
//                             error "SonarQube Quality Gate failed: ${qg.status}"
//                         }
//                     }
//                 }
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 script {
//                     sh "docker build -t ${ECR_REPO_NAME}:latest ."
//                 }
//             }
//         }

//         stage('Push to ECR') {
//             steps {
//                 script {
//                     sh """
//                         aws ecr get-login-password --region ${AWS_REGION} \
//                         | docker login --username AWS \
//                           --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

//                         docker tag ${ECR_REPO_NAME}:latest \
//                           ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

//                         docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest
//                     """
//                 }
//             }
//         }

//         stage('Deploy to EKS') {
//             steps {
//                 script {
//                     sh """
//                         aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
//                         kubectl apply -f k8s/deployment.yaml
//                     """
//                 }
//             }
//         }
//     }
// }



// pipeline {
//     agent any

//     tools {
//         maven 'maven_latest'  // This name must match the one in Global Tool Configuration
//     }

//     environment {
//         SONAR_TOKEN = credentials('sonar-token')  // Jenkins credentials ID
//         AWS_REGION = 'sa-east-1'
//         AWS_ACCOUNT_ID = '211125453684'
//         ECR_REPO_NAME = 'hello-world'
//         EKS_CLUSTER_NAME = 'eks'
//         SONAR_PROJECT_KEY = 'hello-world'
//         SONARQUBE_ENV_NAME = 'SonarQube Scanner'  // This must match Jenkins Sonar config name!
//     }

//     stages {
//         stage('Checkout') {
//             steps {
//                 git branch: 'main',  // Explicitly specify the branch
//                     url: 'https://github.com/ARREYETTA14/CI-CD-Pipeline-for-Java-Microservices-with-Jenkins-Docker-Maven-and-Sonarqube.git',
//                     credentialsId: 'github-patTT' // Replace with your actual Jenkins credentials ID
//             }
//         }

//         stage('Build and SonarQube Analysis') {
//             steps {
//                 script {
//                     withSonarQubeEnv("${SONARQUBE_ENV_NAME}") {
//                         sh """
//                             mvn clean verify sonar:sonar \
//                             -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
//                             -Dsonar.login=${SONAR_TOKEN}
//                         """
//                     }
//                 }
//             }
//         }

//         stage('Quality Gate') {
//             steps {
//                 timeout(time: 2, unit: 'MINUTES') {
//                     script {
//                         def qg = waitForQualityGate()
//                         if (qg.status != 'OK') {
//                             error "SonarQube Quality Gate failed: ${qg.status}"
//                         }
//                     }
//                 }
//             }
//         }

//         stage('Build Docker Image') {
//             steps {
//                 script {
//                     sh "docker build -t ${ECR_REPO_NAME}:latest ."
//                 }
//             }
//         }

//         stage('Push to ECR') {
//             steps {
//                 script {
//                     sh """
//                         aws ecr get-login-password --region ${AWS_REGION} \
//                         | docker login --username AWS \
//                           --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

//                         docker tag ${ECR_REPO_NAME}:latest \
//                           ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

//                         docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest
//                     """
//                 }
//             }
//         }

//         stage('Deploy to EKS') {
//             steps {
//                 script {
//                     sh """
//                         aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
//                         kubectl apply -f k8s/deployment.yaml
//                     """
//                 }
//             }
//         }
//     }
// }




pipeline {
    agent any

    tools {
        maven 'maven_latest'  // Must match the name in Global Tool Configuration
    }

    environment {
        SONAR_TOKEN = credentials('sonar-token')  // Jenkins credentials ID
        AWS_REGION = 'sa-east-1'
        AWS_ACCOUNT_ID = '211125453684'
        ECR_REPO_NAME = 'hello-world'
        EKS_CLUSTER_NAME = 'eks'
        SONAR_PROJECT_KEY = 'hello-world'
        SONARQUBE_ENV_NAME = 'SonarQube Scanner'  // Must match Jenkins Sonar config name
        SONAR_HOST_URL = 'http://54.207.142.153:9000' // 🔥 Replace with your actual EC2 IP or DNS
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/ARREYETTA14/CI-CD-Pipeline-for-Java-Microservices-with-Jenkins-Docker-Maven-and-Sonarqube.git',
                    credentialsId: 'github-patTT' // Replace with your actual GitHub PAT credentials ID
            }
        }

        stage('Build and SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv("${SONARQUBE_ENV_NAME}") {
                        sh """
                            mvn clean verify sonar:sonar \
                              -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                              -Dsonar.host.url=${SONAR_HOST_URL} \
                              -Dsonar.login=${SONAR_TOKEN} \
                              -Dsonar.verbose=true
                        """
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "SonarQube Quality Gate failed: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${ECR_REPO_NAME}:latest ."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} \
                        | docker login --username AWS \
                          --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        docker tag ${ECR_REPO_NAME}:latest \
                          ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest

                        docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh """
                        aws eks --region ${AWS_REGION} update-kubeconfig --name ${EKS_CLUSTER_NAME}
                        kubectl apply -f k8s/deployment.yaml
                    """
                }
            }
        }
    }
}

