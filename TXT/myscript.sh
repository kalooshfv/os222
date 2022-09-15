#!/bin/bash
# Copyright (C) 2020-2022 Cicak Bin Kadal
# This free script is distributed in the hope that it will be 
# useful, but WITHOUT ANY WARRANTY; without even the implied 
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# REV02: Wed 14 Sep 2022 08:00
# REV01: Mon 12 Sep 2022 17:00
# START: Mon 28 Sep 2020 21:00

# ATTN:
# You new to set "REC2" with your own Public-Key Identity!
# Check it out with "gpg --list-key"
# ####################### Replace REC2 ####
REC2="E6EF083730019BDB"
# ####################### ####### #### ####
# REC1: public key
REC1="63FB12B215403B20"
# WEEKURL="http://localhost:4000/WEEK/WEEK.txt"
WEEKURL="https://os.vlsm.org/WEEK/WEEK.txt"
FILES="my*.asc my*.txt my*.sh"
SHA="SHA256SUM"
RESDIR="$HOME/RESULT/"
usage()  { echo "Usage: $0 [-w <WEEK>]" 1>&2; exit 1; }
nolink() { echo "No LINK $1"            1>&2; exit 1; }

# Check current WEEK
unset WEEK DEFAULT
if [ ! -z "${1##*[!0-9]*}" ] ; then
  WEEK=$1
elif [ -z $1 ] ; then
  DEFAULT=1
else while getopts ":w:W:" varTMP
  do
    case "${varTMP}" in
     w|W)
       WEEK=${OPTARG}
       [ ! -z "${WEEK##*[!0-9]*}" ] || usage ;;
    esac
  done
  [ -z $WEEK ] && usage
fi

if [ $DEFAULT ] ; then
  [[ $(wget $WEEKURL -O- 2>/dev/null) ]] || nolink $WEEKURL
  intARR=($(wget -q -O - $WEEKURL | awk '/\| Week / { 
    cmd = "date -d " $2 " +%s"
    cmd | getline mydate
    close(cmd)
    print mydate + (86400 * 6)
  }'))
  DATE=$(date -d $(date +%d-%b-%Y) +%s)
  for II in ${!intARR[@]} ; do
    (( $DATE > ${intARR[$II]} )) || break;
  done
  WEEK=$II
  # echo "DEBUG:TMP:$DEFAULT:W[$WEEK]:$1:$DATE:"
fi

(( WEEK > 11 )) && WEEK=11
WEEK=$(printf "W%2.2d\n" $WEEK)

# echo $WEEK ; exit

# Is this the correct WEEK?
read -r -p "Is this WEEK $WEEK ? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY]) 
        ;;
    *)
        echo "It is not Week $WEEK!"
        exit 1
        ;;
esac

# TXT
[ -d $RESDIR ] || mkdir -p $RESDIR
pushd $RESDIR
for II in W?? ; do
    [ -d $II ] || continue
    TARFILE=my$II.tar.bz2
    TARFASC=$TARFILE.asc
    rm -vf $TARFILE $TARFASC
    echo "tar cfj $TARFILE $II/"
    tar cfj $TARFILE $II/
    echo "gpg --armor --output $TARFASC --encrypt --recipient $REC1 --recipient $REC2 $TARFILE"
    gpg --armor --output $TARFASC --encrypt --recipient $REC1 --recipient $REC2 $TARFILE
done
popd

if [[ "$WEEK" != "W00" ]] && [[ "$WEEK" != "W01" ]] ; then
    II="${RESDIR}my$WEEK.tar.bz2.asc"
    echo "Check and move $II..."
    [ -f $II ] && mv -vf $II .
fi

echo "rm -f $SHA $SHA.asc"
rm -f $SHA $SHA.asc

echo "sha256sum $FILES > $SHA"
sha256sum $FILES > $SHA

echo "# ################ CHECKSUM ###### #########"
echo "sha256sum -c $SHA"
sha256sum -c $SHA

echo "# ################# SIGNING CHECKSUM ######### ######### ########"
echo "gpg --output $SHA.asc --armor --sign --detach-sign $SHA"
gpg --output $SHA.asc --armor --sign --detach-sign $SHA

echo "# ################# VERIFY ######### ######### ######### ########"
echo "gpg --verify $SHA.asc $SHA"
gpg --verify $SHA.asc $SHA

echo ""
echo "==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ===="
echo "==== ==== ==== ATTN: is this WEEK $WEEK ?? === ==== ==== ===="
echo "==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ==== ===="
echo ""

exit 0
