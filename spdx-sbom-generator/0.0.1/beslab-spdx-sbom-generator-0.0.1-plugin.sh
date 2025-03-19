#!/bin/bash
function install_docker() {

	__besman_echo_no_colour "Checking if Docker is installed..."

	if command -v docker >/dev/null 2>&1; then
		__besman_echo_yellow "Docker is already installed"
		docker --version
	else
		__besman_echo_white "Docker not found. Installing Docker..."

		# Update package index
		sudo apt-get update

		# Install required packages
		sudo apt-get install -y \
			apt-transport-https \
			ca-certificates \
			curl \
			gnupg \
			lsb-release

		# Add Docker's official GPG key
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

		# Set up stable repository
		echo \
			"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

		# Install Docker Engine
		sudo apt-get update
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io

		# Start Docker service
		sudo systemctl start docker
		sudo systemctl enable docker

		# Add current user to docker group
		sudo groupadd docker
		sudo usermod -aG docker $USER
		# newgrp docker


		__besman_echo_yellow "Docker installed successfully!"
		docker --version
	fi
}

function install_docker_compose() {
	__besman_echo_no_colour "Checking if Docker Compose is installed..."

	if command -v docker-compose >/dev/null 2>&1; then
		__besman_echo_yellow "Docker Compose is already installed"
		docker-compose --version
	else
		__besman_echo_white "Docker Compose not found. Installing latest version..."

		# Download the latest version of Docker Compose directly from GitHub releases
		sudo curl -L "https://github.com/docker/compose/releases/download/latest/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

		# check if operation successful
		if [ $? -ne 0 ]; then
			__besman_echo_red "Failed to download Docker Compose."
			return 1
		fi
		# Apply executable permissions
		sudo chmod +x /usr/local/bin/docker-compose

		__besman_echo_yellow "Docker Compose installed successfully!"
		docker-compose --version
		if [ $? -ne 0 ]; then
			__besman_echo_red "Failed to download Docker Compose."
			return 1
		fi
	fi
}


function __beslab_install_Spdx_Sbom_Generator() {

    install_docker
    install_docker_compose || return 1

    if [ "$(docker ps -aq -f name=spdx_sbom_generator)" ];then
       docker stop spdx_sbom_generator
       docker container rm --force spdx_sbom_genrator
    fi

    docker create --name spdx_sbom_generator -p 80:80 spdx/spdx-sbom-generator
    docker start spdx_sbom_generator
}

function __beslab_uninstall_Spdx_Sbom_Generator() {

	__besman_echo_no_colour "Stopping and removing $BESLAB_OIAB_BUYER_APP"
	cd "$BESLAB_OIAB_BUYER_APP_DIR" || return 1
	if [ "$(docker ps -aq -f name=spdx_sbom_generator)" ];then
          docker stop spdx_sbom_generator
          docker container rm --force spdx_sbom_generator
        fi
	cd "$HOME" || return 1
}

function __beslab_plugininfo_Spdx_Sbom_Generator()
{
	cat <<EOF
### Plugin Information

#### Description:

This plugin is to install spdx-sbom-generator to get the SBOM of OSS.

#### Version:

latest


#### Usage:

To use the plugin, run the following command:

bli install plugin Spdx_Sbom_Generator 0.0.1

EOF

}
