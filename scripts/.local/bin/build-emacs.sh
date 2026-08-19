#!/usr/bin/env bash

# set -x

# Defaults for unspecified options.

num_jobs=$(cat /proc/cpuinfo | grep 'core id' | wc -l)
source_location=$HOME/SourceCode/emacs
source_tag=master
emacs_repo="https://github.com/emacs-mirror/emacs.git"
# do the options

while getopts g:p:s:t: flag
do
    case "${flag}" in
        g) puregtk=${OPTARG};;
        p) num_jobs=${OPTARG};;
        s) source_location=${OPTARG};;
        t) source_tag=${OPTARG};;
    esac
done

emacs_src=$source_location

echo "NUMBER OF PARALLEL JOBS: $num_jobs"
echo "IN SOURCE TREE: $source_location"
echo "For Source tag: $source_tag"

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
# echo "using $emacs_src source directory"

# if the source directory exists, use it, otherwise clone it and use
# the new clone

# if ( $puregtk )
# then
#     echo "Cloning puregtk emacs source from https://github.com/fejfighter/emacs"
#     git clone -b pgtk-nativecomp https://github.com/fejfighter/emacs $emacs_src
#     # cd $emacs_src
#     echo [Done.]

if [[ -d $emacs_src ]]
then
    cd $emacs_src
else
    echo "Cloning emacs source from $emacs_repo"
    git clone "$emacs_repo" "$emacs_src"
    cd $emacs_src
    echo [Done.]
fi

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Cleaning old build artifacts... "
make distclean 2>/dev/null

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Stashing any remaining local files so checkout/fetch can work..."
git stash

echo "Refreshing sources from upstream..."
echo "Checking out $source_tag ..."
git checkout $source_tag &&
echo "[ Done. ]"

git fetch --all && git pull --all &&

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Running autogen.sh (must run AFTER pull, BEFORE configure)..."
./autogen.sh || { echo "autogen.sh failed!"; exit 1; }

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Configuring emacs source code for version $source_tag... "

## native comp (--with-json removed: JSON is built-in since Emacs 28+)
echo "Configuring with emacs Native Compilation for elisp..."
./configure --with-native-compilation --with-pgtk --with-gnutls --with-imagemagick --with-jpeg --with-png --with-rsvg --with-tiff --with-wide-int --with-xml2 || { echo "configure failed!"; exit 1; }

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Configured. Building with $num_jobs workers..."

make -j$num_jobs bootstrap || { echo "Build failed!"; exit 1; }

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Build complete. Installing..."
sudo make install || { echo "Install failed!"; exit 1; }

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Emacs installed successfully!"
emacs --version | head -1

