#!/bin/bash
SUDO=''
if [[ $EUID -ne 0 ]]; then
    SUDO='sudo'
fi

user_input(){
    printf "$1"
    read -n 1
}

check_packages(){
    REQUIRED_PACKAGES=python3.6,python3.8,python3.6-dev,python3.8-dev,python3.6-venv,python3.8-venv
    clear
    printf "Checking for required packages:\n\n"
    for REQUIRED_PACKAGE in ${REQUIRED_PACKAGES//,/ }; do        
        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PACKAGE|grep "install ok installed")
        printf "\tChecking for %s: %s\n" "$REQUIRED_PACKAGE" "$PKG_OK"
        if [ "" = "$PKG_OK" ]; then
            printf "\t%s not found. Installing\n" "$REQUIRED_PACKAGE"
            user_input "\tPress any key to continue...\n"
            $SUDO apt-get -y install $REQUIRED_PACKAGE
        fi
    done
    printf "\nCheck packages completed ...\n"
    sleep 1
}

check_virtualenv(){
    ARRAY_BINENV=( "python3.6:venv36" "python3.8:venv38" )
    clear
    printf "Checking for required virtualenv:\n\n"
    for python_ver in "${ARRAY_BINENV[@]}" ; do
        BIN_ITEM="${python_ver%%:*}"
        VENV_ITEM="${python_ver##*:}"
        if [[ -d "$VENV_ITEM" ]]
        then
            printf "\t%s exists on your filesystem.\n\n" "$VENV_ITEM"
        else
            printf "\t%s NOT exists on your filesystem.\n" "$VENV_ITEM"
            if ! command -v $BIN_ITEM &> /dev/null
            then
                printf "\t%s could not be found.\n" "$BIN_ITEM"
                printf "\tCannot create virtualenv %s with %s\n" "$VENV_ITEM" "$BIN_ITEM"
                exit
            else
                printf "\tCreating virtualenv on %s with %s\n" "$VENV_ITEM" "$BIN_ITEM"
                user_input "\n\tPress any key to continue...\n"
                $BIN_ITEM -m venv $VENV_ITEM
            fi
        fi
    done
    printf "\nCheck virtualenv completed ...\n"
    sleep 1
}

build_release(){   
    RELEASE_VERSIONS=36,38
    clear
    printf "Build release:\n"
    
    for CURRENT_VER in ${RELEASE_VERSIONS//,/ }; do 
        VENV_PATH_ITEM="venv${CURRENT_VER}"
        OUT_PATH_ITEM="out${CURRENT_VER}"
        BUILD_PATH_ITEM="build${CURRENT_VER}"
        if [[ -d "$VENV_PATH_ITEM" ]]
        then
            printf "\t%s exists on your filesystem. Compiling with %s ...\n\n" "$VENV_PATH_ITEM" "$CURRENT_VER"

            source $VENV_PATH_ITEM/bin/activate
            pip install --upgrade pip
            pip install wheel
            pip install -r requirements.txt --quiet
            rm -rf $BUILD_PATH_ITEM $OUT_PATH_ITEM && \
            mkdir $OUT_PATH_ITEM && \
            mv ./__main__.py ./main.py && \
            python compile.py build_ext --inplace && \
            mv ./main.py ./__main__.py && \
            cp ./main_compile/__main__.py "$OUT_PATH_ITEM"__main__.py && \
            cp ./config.json "$OUT_PATH_ITEM"config.json && \
            find . -maxdepth 1 -cmin -3 -type f -name "*.c" -exec mv "{}" $OUT_PATH_ITEM \; && \
            find . -maxdepth 1 -cmin -3 -type f -name "*.so" -exec mv "{}" $OUT_PATH_ITEM \; && \
            rm -rf $BUILD_PATH_ITEM
            deactivate

            printf "\nBuild complete for %s ...\n\n" "$CURRENT_VER"
            sleep 1
        else
            printf "\t%s not exists on your filesystem. Cannot compile!!!\n" "$VENV_PATH_ITEM"
            clear
        fi
    done
}

clear
check_packages
check_virtualenv
build_release
