#/bin/bash

set -e
SOURCE_ZIP=$1
if [[ -z $SOURCE_ZIP ]]; then
    echo "You need to specify a source zip for us to analyze..."
    echo "Like this: ./sanity.sh <the name of your zip>"
    exit 1
fi
TMP=./tmp
rm -rf $TMP/*
# First, try to unzip the directory into tmp
echo "Unzipping project source dir..."
unzip -o -q $SOURCE_ZIP -d $TMP

echo "Can I find the source directory?"
if [ ! -d "$TMP/src" ]; then
    if [ -d "$TMP/prog1" ]; then
        echo "Don't zip the prog1 folder -- zip the CONTENTS of that folder."
    fi
    echo "The source (src) directory needs to be in the root of your zip file: It seems to be missing. "
    exit 1
fi
echo "Found the source directory!"
# Check that it compiles. 
echo "Trying to compile..."
CLASSFILES=$TMP/bin/assignment
javac -d $CLASSFILES $TMP/src/main/java/assignment/*.java

echo "Successfully compiled!"
echo "Looking for required signatures..."
SIG_FILE=$TMP/sigs
CLASSFILE_LIST=$(find $CLASSFILES -type f)
for f in $CLASSFILE_LIST; do
    javap -p $f >> $SIG_FILE
done

cat signatures.txt | while read sig; do
    #Read the split words into an array based on comma delimiter
    if [[ -z $sig ]]; then
	    break
    fi
    IFS=':'; SPLITSIG=($sig); unset IFS;
    # readarray -d : -t SPLITSIG <<< "$sig"
    CLASSNAME=${SPLITSIG[0]}
    METHODNAME=${SPLITSIG[1]}
    METHODFILE=$TMP/methods
    awk "/$CLASSNAME/,/}/" $SIG_FILE > $METHODFILE
    if grep -qF "$METHODNAME" $METHODFILE; then
	    continue
    else
        echo "ERROR: MISSING FIELD"
        echo "Class: $CLASSNAME"
        echo "Missing method: $METHODNAME"
        exit 1
    fi

done
echo "Found all signatures!"
echo "Looking for report..."
PDFS=$(ls $TMP/*.pdf)
if [ ! -z $PDFS ]; then
    echo "Found possible reports: $PDFS" 
else
    echo "NO REPORT FOUND! Add a pdf file to your zip. "
    exit 1
fi

echo "Check complete! Looks like that zip is good to go!"
