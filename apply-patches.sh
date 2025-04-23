#!/bin/bash

source_dir=${1}
target_dir=${2}


for patch_file in $(ls ${source_dir}/*); do
  patch -d ${target_dir} -p1 < ${patch_file}
done
