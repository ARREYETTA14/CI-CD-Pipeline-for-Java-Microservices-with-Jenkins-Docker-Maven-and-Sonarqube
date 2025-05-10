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


# Import the Corretto GPG key (if you haven't already):
sudo rpm --import https://yum.corretto.aws/corretto.key

# Add the Corretto YUM repo:
sudo curl -Lo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo

# Install Amazon Corretto 17:
sudo yum install java-17-amazon-corretto -y

# Java version
java -version  # Check if Java is installed

# Append this to your shell config (~/.bashrc or ~/.bash_profile):
export JAVA_HOME=/usr/lib/jvm/java-17-amazon-corretto
export PATH=$JAVA_HOME/bin:$PATH

# Then run:
source ~/.bashrc

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
- **Kubernetes CLI**: Run ```kubectl``` commands in pipeline
- **Kubernetes Credentials**: Handle kubeconfig / auth securely
- **Kubernetes Credentials Provider**: Pull secrets from K8s if needed

Go to **Manage Jenkins** > **Manage Plugins** > **Available** > Search for and install these plugins.

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
	You should see SonarQube and Postgresql containers running perfectly well.

### 3.2 - Integrating SonarQube with GitHub for code analysis
- Create a **Github App** on Github.
	- In GitHub, Navigate to:
 		- ```Settings``` → ```Developer settings``` → ```GitHub Apps``` → ```New GitHub App```.
	- Fill in the following:
		- **Github App name**: A recognisable name.
		- **Home page URL**: The full URL to your GitHub repo. Copy from the browser once in the repo.
    		- **Callback URL**: Same as the Homepage URL.
        	- You can **uncheck** ```Active``` at the webhook section.
           	- Set Permissions:
				- Repository Permissions:
					- **Checks**: Read & write
					- **Contents**: Read-only
	   				- **Pull requests**: Read & write
					- Metadata: Read-only
					- **Commit statuses**: Read & write
					- **Merge queues**: Read & write
					- **Projects**: Read & write
					- **Packages**: Read & write
					- **Issues**: Read & write
					- **Environments**: Read & write
					- **Deployments**: Read & write
					- **Actions**: Read & write

	      
				- Organisation Permissions (if applicable):
					- **Administration**: Read & write
					- **Blocking users**: Read & write
					- **Members**: Read & write
					- **Personal Access Token**: Read & write
					- **Projects**: Read & write
	      
				- Account permissions:
					- **Block another account**: Read & write
					- **Email address**: Read & write
					- **SSH signing keys**: Read & write

	- Click ```create Github App```
   -   In the interface that shows, **note down** the ```App ID```, ```Client Id```, Click on **Generate new client secret** to get the 
       ```client secret```, **Generate a private key**, navigate into the downloaded file and copy the key. Keep all these credentials to 
       be used in the SonarQube configuration.
   -   On left tabs, click on ```Install App``` and choose the repositories or organisations you want to integrate with SonarQube​.
             
- Log in to SonarQube
Go to your SonarQube instance (e.g., ```http://<sonarqube-url>:9000```) and log in with your credentials.

- Navigate to:
  	- ```Administration``` → ```Configuration``` → ```General Settings``` → ```DevOps Platform Integrations``` → ```GitHub``` 
- Click: ```Create configuration```. Another way, you can click ``` from GitHub``` on the landing screen to get to the configuration process.
- ​Fill in the Configuration Details:
	- **Configuration name**: A recognisable name, e.g., GitHub Integration
	- **GitHub API URL**: **https://api.github.com/** GOT ```GitHub.com``` and **https://github.company.com/api/v3** for ```Github 	Enterprise```(related to the github internal domain of the company).
	- **GitHub App ID**: Found in your GitHub App settings.
	- **Client ID**: Found in your GitHub App settings.
	- **Client secret**: Found in your GitHub App settings.
	- **Private Key**: Paste the contents of the ```.pem``` file you generated earlier in GitHub.
	- Webhook secret: The secret you set when creating the GitHub App​.
 - Click ```check configuration``` to see if the configuration was done well.
 - Log out of SonarQube and log back in to SonarQube to check if the integration was successful.

- **Import GitHub Repositories into SonarQube(setting up a project for analysis)**
	- On the SonarQube Interface, choose ```from Github```, you will see the repo you integrated, choose ```setup this repo``` at top 	right.
   
   	- Then Choose ```with Github Actions```. Follow the guide on the screen to set up every other thing necessary for the Analysis. 	(The process allows you to set up secrets that will allow GitHub to authenticate to the SonarQube server in order to have analysis 	results processed).
 
   	- When doen with procedure, click on ```continue``` and paste in the ```workflow yaml``` file used to run the Github action that 	will include **triggering sonar analysis**.
 
   	- Choose the appropriate option based on your project you are going to create to build your application. E.g. ```Maven for this project```. Then follow the rest of the process to create the respective files in your github repository.
 
   	- Click ```finish``` below and SonarQube will let you know you are all set and await the running of your ```Github Actions 	Pipeline``` for analysis results to get to the SonarQube UI.
   	
   	- You can trigger the pipeline either **Manually** or by **committing changes** to a branch of that repository. Github action will 	keep off in response to any changes you push, and when this action runs successfully, you will be able to see in your SonarQube UI 	that there are results published as baseline overall code analysis of this branch. 

### 3.3 - Configure Quality Gates in SonarQube
SonarQube isn’t just a fancy dashboard — it’s a bouncer at the gate.
To prevent bad code from getting to prod:
1. Go to the SonarQube UI at ```http://<your_sonarqube_ip>:9000```.
2. Navigate to Quality **Gates** → **Create**
3. Name it ```Strict Java Gate```
4. Add these conditions:
	- **New Critical Issues** > 0 → ❌ Block
	- **New Code Coverage** < 80% → ❌ Block
5. Assign the gate to your project or make it the default.
🛑 This gate will be checked in Jenkins before the deployment proceeds.

### 3.4 Configure SonarQube in Jenkins
1. Navigate to **Jenkins > Manage Jenkins**. Click on ```System``` (that first icon under **"System Configuration"**)
2. Scroll down until you see a section titled:
**📌 SonarQube Servers**
3. Click **Add SonarQube** and give it a name like `SonarQube Scanner`.
4. Add the **Server URL**: `http://<SonarQube-Instance-IP>:9000`
5. Click **Add** next to **Server authentication token**:
   - Generate a token in the SonarQube server in AWS: Go to **My Account → Security** and create a new token (e.g., `jenkins-token`).
   - Paste that token in Jenkins.
6. Check the box: **Enable injection of SonarQube server configuration into the build environment**.

Now Jenkins knows where SonarQube lives and how to talk to it.




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
- **NB:** On the node that helps you connect to the cluster, uninstall the ```awscliv1``` and install ```awscliv2``` before installing ```kubectl```.

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
#### This is to avoid kubectl compatibility issues with the awscliv1.

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
        SONAR_TOKEN = credentials('sonar-token')  // Jenkins credentials ID
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '123456789012'
        ECR_REPO_NAME = 'hello-world'
        EKS_CLUSTER_NAME = 'my-cluster'
        SONAR_PROJECT_KEY = 'hello-world'
        SONARQUBE_ENV_NAME = 'SonarQube Scanner'  // This must match Jenkins Sonar config name!
    }

    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/yourusername/hello-world.git'
            }
        }

        stage('Build and SonarQube Analysis') {
            steps {
                script {
                    withSonarQubeEnv("${SONARQUBE_ENV_NAME}") {
                        sh """
                            mvn clean verify sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.login=${SONAR_TOKEN}
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


```
**NB:** Make sure to change ```<your-account-id>``` and put your actual AWS account id, ```<your-region>``` with the region your ecr is, and ```<your-repo-name>``` with the actual repository name.

## Step 7: Generate the ```deployment.yaml``` and paste in the ```k8s/deployment``` directory in GitHub.

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

