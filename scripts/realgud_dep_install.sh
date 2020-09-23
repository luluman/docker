#!/bin/bash
target=/usr/local
packages=(emacs-{test-simple,load-relative,loc-changes,dbgr})
for pkg in "${packages[@]}"; do
  if [ ! -d $pkg ]; then
    echo "installing '${pkg}'.."
    git clone http://github.com/rocky/${pkg}.git && cd $pkg
  else
    echo "updating '${pkg}'.."
    cd $pkg && git pull
  fi
  [ $? != 0 ] && echo "error: git issues!" && exit 1
  sh ./autogen.sh
  [ $? != 0 ] && echo "error: configure issues!" && exit 1
  ./configure --prefix=$target
  make -j30 && make install
  [ $? != 0 ] && echo "error: make issues" && exit 1
  cd - >/dev/null
done
