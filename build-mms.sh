#!/bin/bash

sdk=${1}


rm -rf hl2sdk-${sdk} metamod-source
git submodule update --init --recursive

cd hl2sdk-${sdk}
git branch -D temp
git checkout -b temp

rm -rf ../.git/modules/$(basename $(readlink -f .))/rebase-apply

# apply patches
for git_patch in $(ls ../patches/hl2sdk-${sdk}/*.patch); do
  git am --3way --ignore-space-change ${git_patch}
done

cd ..

mkdir -p metamod-source/build
cd metamod-source/build

rm -rf ../.git/modules/$(basename $(readlink -f .))/rebase-apply
git submodule update --init
git branch -D temp
git checkout -b temp

# apply patches
for git_patch in $(ls ../../patches/metamod-source/*.patch); do
  git am --3way --ignore-space-change ${git_patch}
done

python3 ../configure.py --sdks ${1}
ambuild
