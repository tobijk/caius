if [ ! -f "environment.sh" ]; then
    echo "The environment.sh file must be sourced locally as '. ./environment.sh'."
elif [ "x$CAIUS_LOCAL_PROJECT_SOURCED" = "x" ]; then
    export TCLLIBPATH="$(pwd)/lib"
    export PATH="$(pwd)/bin:$PATH"

    export PS1="(caius)$PS1"
    export CAIUS_LOCAL_PROJECT_SOURCED="yes"
fi
