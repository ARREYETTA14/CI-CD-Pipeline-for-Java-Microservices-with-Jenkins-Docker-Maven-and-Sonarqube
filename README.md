## Step 1: Set up GitHub Repository
Create a GitHub repository for your project and structure it like this:

```css
hello-world/
├── Dockerfile
├── pom.xml
├── Jenkinsfile
├── k8s/
│   └── deployment.yaml
└── src/
    └── main/java/com/example/HelloWorld.java

```
### 1.1 - Create ```pom.xml``` (Maven Configuration)
In the pom.xml, define the necessary dependencies for the project, including SonarQube analysis, Maven plugin, and Docker plugin. Paste the code in the ```pom.xml``` file in your Github Repo.

This pom.xml includes:

- **Maven Compiler Plugin**: To compile your Java project.
- **SonarQube Plugin**: For static code analysis.
- **Docker Maven Plugin**: This is for building and pushing Docker images.
- **SonarQube Scanner Plugin**: allows Jenkins to run SonarQube code analysis on your source code.

### 1.2 - Create ```HelloWorld.java``` (Java Source Code)
Write the actual Java source code. Inside ```src/main/java/com/example/HelloWorld.java```. 
This is a basic "Hello, World!" program:

## Step 2: Set up Jenkins Server

### 2.1 - Install Jenkins on an EC2 Instance
1. Launch an EC2 Instance in your AWS Console. Choose an Ubuntu or Amazon Linux AMI.
2. Let the **Sg** be open at ports: 22, 80 & 8080(Default Jenkins UI port).
3. Give the server an IAM Role with ```admin``` privileges to communicate with resources in the AWS ecosystem.
4. Install Java, Jenkins, Docker and add Jenkins user to the docker group on your Jenkins EC2 instance:
```bash
# Update and install necessary dependencies
sudo yum update && sudo yum upgrade -y
sudo yum install openjdk-11-jdk -y

# Jenkins now requires Java 17 or higher. Install Amazon Corretto 17:
sudo amazon-linux-extras enable corretto17
sudo yum install java-17-amazon-corretto -y
# Java version
java -version  # Check if Java is installed

# Add Jenkins repository and key
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Install Jenkins
sudo yum install jenkins -y


# Start Jenkins
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Check Jenkins Status
sudo systemctl status jenkins

# make sure correcto 17 is selected
sudo alternatives --config java

# --------------------------------------------
# Step 1: Update the system packages
# --------------------------------------------
sudo yum update -y

# --------------------------------------------
# Step 2: Install required packages
# amazon-linux-extras gives access to extra repos
# --------------------------------------------
sudo amazon-linux-extras install docker -y

# --------------------------------------------
# Step 3: Install Docker
# --------------------------------------------
sudo yum install docker -y

# --------------------------------------------
# Step 4: Start the Docker service
# --------------------------------------------
sudo systemctl start docker

# --------------------------------------------
# Step 5: Enable Docker to start on boot
# --------------------------------------------
sudo systemctl enable docker

# --------------------------------------------
# Step 6: Check Docker version (optional sanity check)
# --------------------------------------------
docker --version

# --------------------------------------------
# Step 7: Add Jenkins user to the Docker group
# This allows Jenkins to run Docker commands without sudo
# --------------------------------------------
sudo usermod -aG docker jenkins

# --------------------------------------------
# Step 8: Restart Docker and Jenkins services
# So group membership changes take effect
# --------------------------------------------
sudo systemctl restart docker
sudo systemctl restart jenkins

# --------------------------------------------
# Step 9: Confirm Jenkins is in Docker group (optional)
# This shows the groups the Jenkins user belongs to
# --------------------------------------------
id jenkins

# --------------------------------------------
# Step 10: You may need to reboot the instance
# for group membership to fully take effect
# --------------------------------------------
echo "Installation complete! You might want to reboot the instance to apply group membership changes."

```
### 2.2 - Install Required Jenkins Plugins.

- **Docker Plugin**: For building Docker images.
- **Maven Plugin**: To run Maven commands.
- **SonarQube Scanner Plugin**: For running SonarQube analysis.
- **Kubernetes Plugin**: For deploying to EKS (Kubernetes).


Go to **Manage Jenkins** > **Manage Plugins** > **Available** > Search for these plugins and install them.

## Step 3: Set up SonarQube
### 3.1 - Install SonarQube
1. Launch an EC2 Instance. ```t3.medium``` instance type.
2. Open the following ports on the server sg: 22,9000(source; Jenkins SG ID).
3. Use the following steps to install SonarQube:
	#### 3.1 - Install Docker & Docker Compose
	```bash
	# Update & install dependencies
	sudo yum update -y
	sudo yum install -y docker
	
	# Start Docker
	sudo systemctl enable docker
	sudo systemctl start docker
	
	# Add ec2-user to Docker group
	sudo usermod -aG docker ec2-user
	
	# Install Docker Compose
	sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
	  -o /usr/local/bin/docker-compose
	
	sudo chmod +x /usr/local/bin/docker-compose
	
	# Verify versions
	docker --version
	docker-compose --version
	```
	#### 3.2 - Create Your Docker Compose File
	```bash
	mkdir sonarqube-docker && cd sonarqube-docker
	sudo nano docker-compose.yml
	```
	Paste this inside:
	
	```yaml
	version: '3.8'
	
	services:
	  db:
	    image: postgres:13
	    container_name: postgres
	    environment:
	      POSTGRES_USER: sonar
	      POSTGRES_PASSWORD: sonar
	      POSTGRES_DB: sonar
	    volumes:
	      - postgres_data:/var/lib/postgresql/data
	    restart: always
	
	  sonarqube:
	    image: sonarqube:latest
	    container_name: sonarqube
	    depends_on:
	      - db
	    ports:
	      - "9000:9000"
	    environment:
	      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
	      SONAR_JDBC_USERNAME: sonar
	      SONAR_JDBC_PASSWORD: sonar
	    volumes:
	      - sonarqube_data:/opt/sonarqube/data
	      - sonarqube_extensions:/opt/sonarqube/extensions
	    restart: always
	
	volumes:
	  postgres_data:
	  sonarqube_data:
	  sonarqube_extensions:
	```
	
	#### 3.3 - Run the Stack
	Before this, uninstall ```awscliv1``` and install ```awscliv2```. If not, there will be an issue of **docker compose not found**.
 	 ```bash
	sudo rm -rf /usr/bin/aws
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   	unzip awscliv2.zip
   	sudo ./aws/install
 	```
	Increase the instance virtual memory so that **Sonarqube** doesn't have issues ```starting```
	```bash
 	# Run this on the EC2 instance (not inside the container):
	sudo sysctl -w vm.max_map_count=262144
 
	# Make it persist across reboots by adding this to /etc/sysctl.conf:
	echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
 
	#Then reload with:
	sudo sysctl -p
	``` 
	```bash
	docker-compose up -d
	```

5. Once SonarQube is running, go to ```http://<your_sonarqube_instance_public_ip>:9000```.
Default creds:

- Username: ```admin```
- Password: ```admin```

5. Make compose file rebooted upon EC2 reboot.
	#### 5.1 - Open the Crontab for Your User (Usually ```ec2-user```)
	```bash 
	crontab -e
	```
	- If it's your first time, it may ask you to choose an editor.
	
		- Pick ```1``` for nano, unless you're feeling like a Vim god.
	
	
	#### 5.2 - Add This to the Bottom of the File
	```bash
	@reboot cd /home/ec2-user/sonarqube-docker && /usr/local/bin/docker-compose up -d
	```
	**NB:** 
	- Check your ```docker-compose``` path — it might not be in ```/usr/local/bin/``` for all systems.
		- Run this to be sure:
		```bash
		which docker-compose
		```
		- Replace ```/usr/local/bin/docker-compose``` with whatever path it gives you.
	
	#### 5.3 - Test start of docker-compose upon instance reboot
	
	- Once your crontab is saved, reboot your instance:
	```bash
	sudo reboot
	```
	- Then wait like 1–2 minutes, reconnect via SSH, and check:
	```bash
	docker ps
	```
	You should see SonarQube and PostgreSQL containers running perfectly well.

### 3.2 - Integrating Sonarqube with GitHub for code analysis
- Login to SonarQube
Go to your SonarQube instance (e.g., ```http://<sonarqube-url>:9000```) and log in with your credentials. Go to your SonarQube instance (e.g., http://<sonarqube-url>:9000) and log in with your credentials.









			
- This token will be used in **Jenkins** to authenticate SonarQube analysis.

## Step 4: Create Dockerfile for Java Application
The Dockerfile will instruct Docker how to create an image from the Java application.
Save the code in the ```Dockerfile``` file in your GitHub repo.

## Step 5: ECR & EKS Setup
1. Create an ECR Repository

- **Go to the AWS Management Console**.
- **Navigate to the ECR Console**:
	- From the AWS Management Console, search for **ECR** > **Repositories**.
- **Create a New Repository**:
	- Click **Create repository**.
	- **Repository Name**: Give it a name, for example, ```hello-world```.
	- **Other settings**: Choose the default settings or adjust based on your requirements.
		- **Tag immutability**: Optional, but useful if you want to prevent overwriting images.
		- **Scan on push**: Enable this to scan images for vulnerabilities upon pushing them to ECR.
- Click **Create repository**.

2. Create an EKS Cluster.
- Follow [Eks Cluster setup guide](https://k21academy.com/docker-kubernetes/amazon-eks-kubernetes-on-aws/)
- You can use the **AWS Recommended Roles** upon creation of the **cluster** Masternode.
- **NB:** On the node that helps you connect to the cluster, uninstall the ```awscliv1``` and install ```awscliv2``` before installing ```kubectl```,  .
**Uninstall the Old AWS CLI (v1)**

```bash
sudo rm -rf /usr/bin/aws
```
	- To double-check it’s gone:
	```bash
	which aws
	# Should return nothing
	```
	- Optional sanity check:
	```bash
	aws --version
	# Should say "command not found"
	```

**Install AWS CLI v2**

	- Download the installer:
	```bash
	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
	```
	- Unzip it:
	```bash
	unzip awscliv2.zip
	```
	- Run the installer:
	```bash
	sudo ./aws/install
	```
	- Confirm installation:
	```bash
	aws --version
	# Should return something like aws-cli/2.x.x
	```
## This is to avoid kubectl compatitbility issues with the awscliv1.

## Step 6: Log into Jenkins Server
### - Add the parameters of the jenkinsfile in the ```Jenkins Global Evironment Varaibles```

1. Set Global Environment Variables in Jenkins
- Go to Jenkins Dashboard
- Click Manage Jenkins
- Click Configure System
- Scroll down to Global Properties
- Check the box for Environment variables
- Add the following variables:

```txt
Name	         Value
AWS_REGION	     us-east-1
AWS_ACCOUNT_ID	 123456789012
EKS_CLUSTER_NAME  my-cluster
ECR_REPO_NAME	  hello-world
SONAR_PROJECT_KEY hello-world
SONAR_HOST_URL	  http://<your-sonarqube-instance-public-ip>:9000
```

2. Add ```sonarqube-token``` in **jenkins credentials**.
- Go to Manage **Jenkins** > **Credentials** > **Global** > **Add Credentials**
- Choose:
	- Kind: ```Secret text```
	- Secret: paste the SonarQube token you just generated
	- ID: ```sonar-token``` ← name it exactly this if your Jenkinsfile is expecting ```credentials('sonar-token')```.
	
3. Update Jenkinsfile to Use Those Variables

```groovy
pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('sonar-token')  // SonarQube token
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '123456789012'
        ECR_REPO_NAME = 'hello-world'
        EKS_CLUSTER_NAME = 'my-cluster'
        SONAR_PROJECT_KEY = 'hello-world'
        SONAR_HOST_URL = 'http://<your-sonarqube-instance-public-ip>:9000'
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/yourusername/hello-world.git'
            }
        }

        stage('Build') {
            steps {
                script {
                    sh 'mvn clean install'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    sh """
                        mvn sonar:sonar \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.login=${SONAR_TOKEN}
                    """
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

```

## Step 7: Generate the ```deployment.yaml``` and paste in the ```k8s/deployment``` directory in GitHub.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world
  template:
    metadata:
      labels:
        app: hello-world
    spec:
      containers:
      - name: hello-world
        image: <your-account-id>.dkr.ecr.<your-region>.amazonaws.com/<your-repo-name>:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: hello-world-service
spec:
  type: LoadBalancer
  selector:
    app: hello-world
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

**NB:** Make sure to change ```<your-account-id>``` and put your actul AWS account id, ```<your-region>``` with the region your ecr is, and ```<your-repo-name>``` with the actual repository name.

## Step 8: Trigger the Jenkins pipeline
- Install GitHub-related plugins (if not already installed):
	- Go to ```Manage Jenkins > Plugin Manager > Available```
		- Search and install:
			- GitHub plugin
			- GitHub Branch Source
			- GitHub API plugin
			- Pipeline: Multibranch

- In Jenkins:
	- Go to ```New Item > Multibranch Pipeline``` (or ```pipeline``` if you use a single branch.
	- Set a name (e.g., ```hello-world-pipeline```).
	- Choose:
		- For Pipeline: Choose ```Pipeline script from SCM```, then:
			- SCM: ```Git```
			- Repo URL: your GitHub/xxxxx/xxxxx repo URL
			- Script Path: leave as ```Jenkinsfile``` (unless it's in a subfolder)
		- For Multibranch Pipeline: Just point it to the repo, Jenkins will auto-scan for branches with a ```Jenkinsfile```.

	- Hit **Save**, and Jenkins will do the rest (automatically clone, find the ```Jenkinsfile```, and run the build).
