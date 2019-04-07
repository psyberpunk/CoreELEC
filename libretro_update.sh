#!/bin/bash

# This file is part of the Lakka project and was created by ToKe79. It is originally from https://github.com/libretro/Lakka-LibreELEC/blob/master/libretro_update.sh
# it has been modified by Shanti Gilbert to work with Sx05RE

[ -z "$BUMPS" ] && BUMPS="no"
[ -z "$LR_PKG_PATH" ] && LR_PKG_PATH="./packages"
usage()
{
  echo ""
  echo "$0 <--all [--exclude list] | --used [--exclude list] | --packages list>"
  echo ""
  echo "Updates PKG_VERSION in package.mk of libretro packages to latest."
  echo " -p list --packages list  Update listed libretro packages"
  echo " -e list --exclude list   Update all/used packages except listed ones"
  echo ""
}

[ "$1" == "" ] && { usage ; exit ; }

case $1 in
  -a | --all )
    s=$1
    shift
    if [ "$1" != "" ] ; then
      case $1 in
        -e | --exclude )
          PACKAGES_EX=""
          x="$1"
          shift
          v="$@"
          [ "$v" == "" ] && { echo "Error: You must provide name(s) of package(s) to exclude after $x" ; exit 1 ; }
          for a in $v ; do
            if [ -f $(find $LR_PKG_PATH -wholename */$a/package.mk) ] ; then
              PACKAGES_EX="$PACKAGES_EX $a"
            else
              echo "Warning: $a is not a libretro package."
            fi
          done
          [ "$PACKAGES_EX" == "" ] && { echo "No valid packages to exclude given! Aborting." ; exit 1 ; }
          ;;
        * )
          echo "Error: After $s use only --exclude (-e) to exclude some packages."
          exit 1
          ;;
      esac
    fi
    # Get list of all libretro packages
    PACKAGES_ALL=`ls $LR_PKG_PATH`
    ;;
  -u | --used )
    s=$1
    shift
    if [ "$1" != "" ] ; then
      case $1 in
        -e | --exclude )
          PACKAGES_EX=""
          x="$1"
          shift
          v="$@"
          [ "$v" == "" ] && { echo "Error: You must provide name(s) of package(s) to exclude after $x" ; exit 1 ; }
          for a in $v ; do
            if [ -f $(find $LR_PKG_PATH -wholename */$a/package.mk) ] ; then
              PACKAGES_EX="$PACKAGES_EX $a"
            else
              echo "Warning: $a is not a libretro package."
            fi
          done
          [ "$PACKAGES_EX" == "" ] && { echo "No valid packages to exclude given! Aborting." ; exit 1 ; }
          ;;
        * )
          echo "Error: After $s use only --exclude (-e) to exclude some packages."
          exit 1
          ;;
      esac
    fi
    ;;
  -p | --packages )
    PACKAGES_ALL=""
    x="$1"
    shift
    v="$@"
    [ "$v" == "" ] && { echo "Error: You must provide name(s) of package(s) after $x" ; exit 1 ; }
    for a in $v ; do
      if [ -f $(find $LR_PKG_PATH -wholename */$a/package.mk) ] ; then
        PACKAGES_ALL="$PACKAGES_ALL $a "
      else
        echo "Warning: $a is not a libretro package - skipping."
      fi
    done
    [ "$PACKAGES_ALL" == "" ] && { echo "No valid packages given! Aborting." ; exit 1 ; }
    ;;
  * )
    usage
    echo "Unknown parameter: $1"
    exit 1
    ;;
esac
if [ "$PACKAGES_EX" != "" ] ; then
  for a in $PACKAGES_EX ; do
    PACKAGES_ALL=$(echo " "$PACKAGES_ALL" " | sed "s/\ $a\ /\ /g")
  done
fi
echo "Checking following packages: "$PACKAGES_ALL
declare -i i=0
declare -i ii=0
for p in $PACKAGES_ALL
do
  f=$(find $LR_PKG_PATH -wholename */$p/package.mk)
  if [ ! -f "$f" ] ; then
    echo "$f: not found! Skipping."
    continue
    else
    echo "working on : $f"
    source config/options "$p"
    source "$f"
  fi
 
  if [ -z "$PKG_VERSION" ] || [ -z "$PKG_SITE" ] ; then
    echo "$f: does not have PKG_VERSION or PKG_SITE"
    echo "PKG_VERSION: $PKG_VERSION"
    echo "PKG_SITE: $PKG_SITE"
    echo "Skipping update."
    continue
  fi
     
if [ $BUMPS != "no" ]; then

  if [ "$p" != "linux" ]; then
    PKG_SITE=$PKG_SITE
  else
    PKG_SITE=$(echo $PKG_URL | sed 's/\/archive.*//g')
  fi
  # echo "URL $PKG_SITE"

  [ -n "$PKG_GIT_BRANCH" ] && GIT_HEAD="heads/$PKG_GIT_BRANCH" || GIT_HEAD="HEAD"
   UPS_VERSION=`git ls-remote $PKG_SITE | grep ${GIT_HEAD}$ | awk '{ print substr($1,1,40) }'`
   if [ "$UPS_VERSION" == "$PKG_VERSION" ]; then
    echo "$PKG_NAME is up to date ($UPS_VERSION)"
    echo ""
    NOUPD=1
   else
    i+=1
     echo "$PKG_NAME updated from $PKG_VERSION to $UPS_VERSION"
    sed -i "s/PKG_VERSION=\"$PKG_VERSION/PKG_VERSION=\"$UPS_VERSION/" $f
    NOUPD=0
   fi
else
  UPS_VERSION=$PKG_VERSION
fi 

# only update SHA256 if version is updated
if [ "$NOUPD" != 1 ]; then
 
  if [ "$GET_HANDLER_SUPPORT" != "git" ]; then  
  
    if grep -q PKG_SHA256 "$f"; then
    echo "PKG_SHA256 exists on $f, clearing"
    sed -i "s/PKG_SHA256=\"$PKG_SHA256\"/PKG_SHA256=\"\"/" $f
    else
    echo "PKG_SHA256 does not exists on $f, creating"
    sed -i -e "s/PKG_VERSION=\"$UPS_VERSION\(.*\)\"/PKG_VERSION=\"$UPS_VERSION\1\"\nPKG_SHA256=\"\"/g" $f
   fi

     source "$f"
    ./scripts/get "$PKG_NAME"
    
    if [ "$p" != "linux" ]; then
    CALCSHA=$(cat ./sources/$PKG_NAME/$PKG_NAME-$UPS_VERSION.*.sha256)
    else
    CALCSHA=$(cat ./sources/$PKG_NAME/linux-$LINUX-$UPS_VERSION.tar.gz.sha256)
    fi
    
    echo "NEW SHA256 $CALCSHA"
    #sed -i -e "s/PKG_VERSION=\"$UPS_VERSION\(.*\)\"\n\(.*\)\PKG_SHA256=\"\"/PKG_VERSION=\"$UPS_VERSION\1\"\nPKG_SHA256=\"$CALCSHA\"/g" $f
    sed -e "/PKG_VERSION=\"$UPS_VERSION\"/{ N; s/PKG_VERSION=\"$UPS_VERSION\".*PKG_SHA256=\"\"/PKG_VERSION=\"$UPS_VERSION\"\nPKG_SHA256=\"$CALCSHA\"/;}" -i $f
    # sed -i "s/PKG_SHA256=\"$PKG_SHA256/PKG_SHA256=\"$CALCSHA/" $f
    ii+=1
  fi
 fi   
 done
echo "$i package(s) bumped. $ii sha256 updated packages"
