#!/bin/sh

##############################################################################
# Functions
##############################################################################

do_clean()
{
    ls scss/ | while read scss_file
    do
        # continue if not a regular file
        test -f scss/$scss_file || continue

        rm -f css/`basename $scss_file .scss`.css
    done

    rm -f css/variables.css
}

do_build()
{
    do_clean
    mkdir -p css

    ls scss/ | while read scss_file
    do
        # continue if not a regular file
        test -f scss/$scss_file || continue

        python3 -c "
import sass, sys
print(sass.compile(filename=sys.argv[1], output_style='expanded', precision=8))
" scss/$scss_file >> css/`basename $scss_file .scss`.css
    done

    rm -f css/variables.css
}

##############################################################################
# Main
##############################################################################

case "$1" in
    build|css)
        do_build
        ;;
    clean)
        do_clean
        ;;
    *)
        echo "Usage: $0 {css|clean}"
        exit 1
        ;;
esac

