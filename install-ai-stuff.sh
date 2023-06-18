#!/bin/bash

# ·c·

# Our constants go here
venvname="sovits-pony"
script_name="svcg-run"	# If I named this just svcg I'm pretty sure it would cause a conflict

function check_gfx_vendor() {
	
	if [ "$(lsmod | grep nvidia_drm)" ]; then
		echo "You are running an NVIDIA card, your system should be compatible."
		gpu="NVIDIA"
	elif [ -x "$(command -v rocminfo)" ]; then
		echo "You are running an AMD card, your system should be compatible."
		gpu="AMD"
	else
		echo "You aren't running an NVIDIA/AMD card or you do not have the proper drivers installed. Only CPU-based inferrence will be available"
		echo "If you are on AMD, make sure you have the ROCm framework installed."
		echo "Install guide for Arch: https://wiki.archlinux.org/index.php?title=GPGPU#ROCm"
		echo "If you are on NVIDIA, make sure you are running the proprietary drivers instead of Nouveau."
		echo "Guides on how to do this for your distro can be easily found."
		read -p "Type Y if you wish to continue, any other key if you wish to exit: " response

		response=$(echo -n $response | tr -cd '[:alnum:] [:space]' | tr '[:space:]' '-' | tr '[:lower:]' '[:upper:]')
		if [ ! -z $response ] && [ $response == Y ]; then
			echo "Installing with CPU support only..."
			gpu="NONE"
		else
			echo "Exiting..."
			exit
		fi
	fi
}

function setup_venv() {
	# First check to see if anaconda is installed, if not, we'll proceed.
	if [ ! command -v conda &> /dev/null ]; then
		echo "Anaconda not installed, let's fix that..."
		wget -O miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-py310_23.3.1-0-Linux-x86_64.sh"
		( exec ./miniconda.sh )
		source ~/.bashrc
	fi
	conda create -n $venvname python=3.10 pip

	# This command is necessary because otherwise Anaconda refuses to initialize the
	# venv within a shell script. There might be a better way but I haven't found it yet

	source ~/miniconda3/etc/profile.d/conda.sh
	conda activate $venvname
	python -m pip install -U pip setuptools wheel

	case $gpu in
        	NVIDIA)		pip install -U torch torchaudio --index-url https://download.pytorch.org/whl/cu118;;
        	AMD)            pip install -U torch torchaudio --index-url https://download.pytorch.org/whl/rocm5.4.2;;
        	NONE)           echo "Installing without GPU support, skipping";;		# It still seems to install CUDA libraries even if I omit the command, interesting
	esac

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
mkdir 
echo "SVC install script v0.2 by ricy"
check_if_env_exists
if [ $? == 1 ]; then
	check_gfx_vendor
	setup_venv
#	setup_sovits_rt
	setup_jank_shell_script
else
	echo "SVC already installed."
	read -p "Would you like to uninstall SVC? Type Y for yes, any other key or nothing for no: " answer

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
