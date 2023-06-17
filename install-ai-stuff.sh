#!/bin/bash

# ·c·

# Our constants go here
venvname="sovits-pony"
script_name="svcg-run"	# If I named this just svcg I'm pretty sure it would cause a conflict

function check_gfx_vendor() {
	
	if [ "$(lsmod | grep nvidia_drm)" ]; then
		echo "You are running an NVIDIA card, your system should be compatible."
	else
		# I'm pretty sure other GPUs are supported, if they are, let me know or feel free to
		# modify this script ·c·
		echo "You aren't running an NVIDIA card or you do not have the proprietary drivers installed. Exiting..."
		exit
	fi
}

function setup_anaconda() {
	wget -O miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-py310_23.3.1-0-Linux-x86_64.sh"
	exec miniconda.sh
}

function setup_venv() {
	# First check to see if anaconda is installed, if not, we'll proceed.
	if ! command -v conda &> /dev/null
	then
		echo "Anaconda not installed, let's fix that..."
		setup_anaconda
	else
		echo "Anaconda most likely installed, I'll skip this..."
		# read -p "Please type the name for your venv here: " venvname
		conda create -n $venvname python=3.10 pip

		# This command is necessary because otherwise Anaconda refuses to initialize the
		# venv within a shell script ·c·

		source ~/miniconda3/etc/profile.d/conda.sh
		conda activate $venvname
		python -m pip install -U pip setuptools wheel
		pip install -U torch torchaudio --index-url https://download.pytorch.org/whl/cu118
	fi
}

function setup_sovits_rt() {
	if [ ! -d "$(pwd)/so-vits-svc-fork" ]; then
		echo "so-vits-svc-fork not downloaded yet, let's fix that..."
		git clone https://github.com/voicepaw/so-vits-svc-fork
	fi
	cd $(pwd)/so-vits-svc-fork
	pip install -U so-vits-svc-fork
}


# This is so that you don't have to run "conda activate blahblahblah" before running "svcg".
# I'm pretty sure there is a better way to do this, but if this works this works ·c·

function setup_jank_shell_script() {

	# Create and populate the script
	touch $script_name
	echo -e '#!/bin/bash\n' > $script_name
	echo -e "source ~/miniconda3/etc/profile.d/conda.sh\nconda activate $venvname\nsvcg" > $script_name

	# Make the script executable and move it to user-wide bin directory
	chmod +x $script_name
	mv $script_name ~/.local/bin
}

function uninstall_sovits_fork() {
	echo "Uninstalling..."
	rm ~/.local/bin/$script_name
	conda remove -n $venvname --all
}

function check_if_env_exists() {
	if [ -d ~/miniconda3/envs/$venvname ]; then
		return 0
	else
		return 1
	fi	
}

clear
echo "SVC install script v0.1 by ricy"
check_if_env_exists
if [ $? == 1 ]; then
	check_gfx_vendor
	setup_venv
	setup_sovits_rt
	setup_jank_shell_script
else
	echo "SVC already installed."
	read -p "Would you like to uninstall SVC? Type Y for yes, any other key or nothing for no." answer

	# Sanitize input and make the answer uppercase
	answer=$(echo -n $answer | tr -cd '[:alnum:] [:space]' | tr '[:space:]' '-' | tr '[:lower:]' '[:upper:]')
	if [ ! -z $answer ] && [ $answer == Y ]; then
		echo "Ok, uninstalling..."
		uninstall_sovits_fork
	else
		echo "Ok, exiting..."
	fi
	exit
fi
conda deactivate
echo -e "\nDone! Now run svcg-run in your terminal and (hopefully) you should be able to launch it! ·c·"
