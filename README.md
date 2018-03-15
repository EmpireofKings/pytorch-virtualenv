# A PyTorch virtualenv wrapper

This is a simple Bash script and library that allows you to activate a PyTorch virtualenv and use Python3 (I am not judging, but you should use Python3, if you can) to develop your Machine Learning code.

It will also fail if Python3 or virtualenv is not installed. You will still have to install CUDA (with your preferred version), if you wish to use it with PyTorch.

Works with:
- Python 3, version 3.5
- Virtualenv version 15 or older
- PyTorch 0.3.1
- CUDA versions 8.0, 9.0 and 9.1 (this is a strong requirement from PyTorch)

**Note:** If the right CUDA version is not found, the CPU version of PyTorch will be used instead. 

If you wish to use a different version of Python (e.g. 3.6) or PyTorch (when available), please edit the **lib/pytorch-pip3-lib.sh** file and update the **pytorch_version** + **pytorch_python_version** variables.  

## A simple usage example

The same example can be found in *example.sh*:

```bash
# this is the actual script path
script_path=$(dirname "$(readlink -f "$0")")
# import the pytorch virtual env script
source "${script_path}/lib/pytorch-pip3-lib.sh"

# Setup: Please note that the pytorch-pip3-lib does not provide any defaults,
# so if the env folder is not provided, it will most likely fail
#
# The virtual environment folder to create (the path has to be writeable)
env_folder="${script_path}/../env"
# The pip dependencies file or "requirements" as everybody else calls it
dependencies_path="${script_path}/../dependencies.txt"
# post install stuff. Python3 scripts to be executed after the virtual environment creation
# e.g. nltk dictionaries or other datasets
# Note: the virtual env and all its dependencies are installed at this point
# Important note: This script is executed only if the virtual env is created. It is not executed on activation
postinstall_path="${script_path}/../nltk_postinstall.py"

# activate or create the env folder
# This will also setup a trap to deactivate the virtualenv once the script exits
activate_or_create_env ${env_folder}

# Do some work here. It can be any type of comamnd or other script calls at this point
# Important note: The src/ path is threated as source folder and no longer as a python package
# so you can safely place all your important work into a src/ folder
echo "Do some work here"
```
