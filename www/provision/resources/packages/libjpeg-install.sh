#!/bin/bash
mkdir temp
tar -xvzf jpegsrc.v9b.tar.gz -C temp/
cd temp/jpeg-9b/
./configure
make
make install

cd ../../
sudo rm -rf temp

