#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2018 Ovidiu Șerban, ovidiu@roboslang.org
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


script_path=$(dirname "$(readlink -f "$0")")

cuda_version="/usr/local/cuda/version.txt"
pytorch_pack=""
pytorch_version="0.3.1"
pytorch_python_version="cp35"

function check_dependency {
    param=$1
    [[ -z "${param}" ]] && echo "Missing param in ${FUNCNAME}" && return 1

    command -v ${param} 2 >& 1 > /dev/null
    return $?
}

function fail_on_missing {
    param=$1
    check_dependency ${param}
    if [ $? != 0 ]; then
        echo "Dependency missing: ${param}"
        exit 1
    fi
}

function check_cuda_version {
    pytorch_arch="cpu"
    if [ -f ${cuda_version} ] ; then
        CVERSION=$(cat ${cuda_version})
        if [[ ${CVERSION} =~ 8[.][0-9]+[.][0-9]+ ]]; then
            echo "Found CUDA version 8.0"
            pytorch_arch="cu80"
        elif [[ ${CVERSION} =~ 9[.]1[.][0-9]+ ]]; then
            echo "Found CUDA version 9.1"
            pytorch_arch="cu91"
        elif [[ ${CVERSION} =~ 9[.][0-9]+[.][0-9]+ ]]; then
            echo "Found CUDA version 9.0"
            pytorch_arch="cu90"
        else
            echo "Could not find CUDA, using CPU version"
        fi
    else
        echo "Could not find CUDA, using CPU version"
    fi
    pytorch_pack="http://download.pytorch.org/whl/${pytorch_arch}/torch-${pytorch_version}-${pytorch_python_version}-${pytorch_python_version}m-linux_x86_64.whl"
}

function rollback_env {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    echo "Rolling back the env changes from ${env_folder}"
    rm -rf ${env_folder}
    pytorch_pack=""
}

function patch_env {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    echo "Patching the virtualenv ${env_folder} ..."
    echo "" >> ${env_folder}/bin/activate
    echo 'export PYTHONPATH="${PYTHONPATH}:src/"' >> ${env_folder}/bin/activate
}

function deactivate_env {
    check_dependency "deactivate"
    if [ $? == 0 ]; then
        # the virtual env is still active
        echo 'Virtualenv deactivate ...'
        deactivate || true
    fi
}

function activate_env {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    echo "Activating the virtualenv in ${env_folder}"
    source ${env_folder}/bin/activate
    trap deactivate_env EXIT SIGINT SIGTERM
}

function install_dependencies {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    echo "Installing dependencies"

    pip install ${pytorch_pack}
    if [ $? != 0 ]; then
        echo "Failed to install PyTorch"
        rollback_env ${env_folder}
        exit 1
    fi
    pytorch_pack=""

    pip install -r ${dependencies_path}
    if [ $? != 0 ]; then
        echo "Failed to install project dependencies"
        rollback_env ${env_folder}
        exit 1
    fi


    if [[ ! -z ${postinstall_path} && -f ${postinstall_path} ]]; then
        echo "Installing post-install dependencies ..."
        python ${postinstall_path}
        if [ $? != 0 ]; then
            echo "Failed to install post-install dependencies"
            rollback_env ${env_folder}
            exit 1
        fi
    else
        echo "Missing post install dependencies ..."
    fi

}

function create_env {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    echo "Trying to create the virtualenv in ${env_folder}"

    check_cuda_version
    if [ -z ${pytorch_pack} ]; then
        echo "Could not create virtualenv due to missing dependency: PyTorch"
        exit 1
    fi

    virtualenv -p python3 ${env_folder}
    patch_env ${env_folder}
    activate_env ${env_folder}
    install_dependencies ${env_folder}
}

function activate_or_create_env {
    env_folder=$1
    [[ -z "${env_folder}" ]] && echo "Missing env_folder in ${FUNCNAME}" && return 1

    fail_on_missing "python3"
    fail_on_missing "virtualenv"

    if [ -d ${env_folder} ]; then
        activate_env ${env_folder}
    else
        create_env ${env_folder}
    fi
}
