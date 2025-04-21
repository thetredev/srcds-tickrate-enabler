#!/bin/bash

set -e

sdk=${1}
current_git_branch=$(git branch --show-current)
patches_dir=patches/linux/gcc

clean_build=${2}

if [[ ${clean_build} ]]; then
  rm -rf output/*
  rm -rf metamod-source/build
  rm -rf hl2sdk-${sdk} metamod-source

  git submodule update --init --recursive
else
  rm -rf output/srcds_tickrate_enabler*.tar.gz
fi

cd hl2sdk-${sdk}
rm -rf ../.git/modules/$(basename $(readlink -f .))/rebase-apply

git_ref=$(git rev-parse HEAD)
git reset --hard
git checkout ${git_ref}
git branch -D temp
git checkout -b temp

# apply patches
for git_patch in $(ls ../${patches_dir}/hl2sdk-${sdk}/*.patch); do
  git am --3way --ignore-space-change ${git_patch}
done

cd ..
git checkout ${current_git_branch}

mkdir -p metamod-source/build
cd metamod-source/build
rm -rf ../.git/modules/$(basename $(readlink -f .))/rebase-apply

git_ref=$(git rev-parse HEAD)
git reset --hard
git checkout ${git_ref}
git branch -D temp
git checkout -b temp

python3 -m venv .venv
source .venv/bin/activate
pip install wheel

test -d .ambuild-git || git clone https://github.com/alliedmodders/ambuild .ambuild-git
pip install .ambuild-git

# apply patches
for git_patch in $(ls ../../${patches_dir}/metamod-source/*.patch); do
  git am --3way --ignore-space-change ${git_patch}
done

python3 ../configure.py --sdks ${1}
ambuild

cd ../..
git checkout ${current_git_branch}
