#!/bin/bash
set -ex

yum update -y
yum install -y \
    atlas-devel \
    atlas-sse3-devel \
    blas-devel \
    gcc \
    gcc-c++ \
    lapack-devel \
    python3 \
    python3-devel \
    findutils \
    tar \
    zip


do_pip () {
#  pip3 install --upgrade pip wheel
#  pip3 install --upgrade --no-binary numpy numpy
#  pip3 install --upgrade --no-binary scipy scipy
#  pip3 install --upgrade numpy
#  pip3 install --upgrade scipy
  test -f /outputs/requirements.txt && pip3 install -r /outputs/requirements.txt
}

strip_virtualenv () {
    # Clean up docs
    find $VIRTUAL_ENV -name "*.dist-info" -type d -prune -exec rm -rf {} \;
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    # TODO: It breaks astropy if you remove its 'tests' folder. Figure out
    # how to gracefully skip this directory (my bash-foo) isn't up to it.

    tar -cvf "$VIRTUAL_ENV/lib64/python3.7/site-packages/astropy.tar" "$VIRTUAL_ENV/lib64/python3.7/site-packages/astropy"
    rm -rf "$VIRTUAL_ENV/lib64/python3.7/site-packages/astropy"

    # Clean up tests
    find $VIRTUAL_ENV -name "tests" -type d -prune -exec rm -rf {} \;
    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    tar -xvf "$VIRTUAL_ENV/lib64/python3.7/site-packages/astropy.tar"
    rm -rf "$VIRTUAL_ENV/lib64/python3.7/site-packages/astropy.tar"

#    echo "venv original size $(du -sh $VIRTUAL_ENV | cut -f1)"
#    find $VIRTUAL_ENV/lib64/python3.7/site-packages/ -name "*.so" | xargs strip
#    echo "venv stripped size $(du -sh $VIRTUAL_ENV | cut -f1)"

    # remove the numpy - it's included in the layer we will add to the lambda function
    rm -rf $VIRTUAL_ENV/lib/python3.7/site-packages/numpy*
    rm -rf $VIRTUAL_ENV/lib64/python3.7/site-packages/numpy*
#    rm -rf $VIRTUAL_ENV/lib64/python3.7/site-packages/lib

    cp /outputs/process.py $VIRTUAL_ENV

    pushd $VIRTUAL_ENV && zip -r -9 -q /tmp/process.zip process.py ; popd
    pushd $VIRTUAL_ENV/lib/python3.7/site-packages/ && zip -r -9 --out /tmp/partial-venv.zip -q /tmp/process.zip * ; popd
    pushd $VIRTUAL_ENV/lib64/python3.7/site-packages/ && zip -r -9 --out /outputs/venv.zip -q /tmp/partial-venv.zip * ; popd
    echo "site-packages compressed size $(du -sh /outputs/venv.zip | cut -f1)"

    pushd $VIRTUAL_ENV && zip -r -q /outputs/full-venv.zip * ; popd
    echo "venv compressed size $(du -sh /outputs/full-venv.zip | cut -f1)"
}

shared_libs () {
    libdir="$VIRTUAL_ENV/lib64/python3.7/site-packages/lib/"
    mkdir -p $VIRTUAL_ENV/lib64/python3.7/site-packages/lib || true
    cp /usr/lib64/atlas/* $libdir
    cp /usr/lib64/libquadmath.so.0 $libdir
    cp /usr/lib64/libgfortran.so.4 $libdir
}

main () {
    python3 -m venv /sklearn_build
    source /sklearn_build/bin/activate

    do_pip

#    shared_libs

    strip_virtualenv

}
main
