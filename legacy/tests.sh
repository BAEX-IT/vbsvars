#!/usr/bin/bash

echo "Hello! We will run a function!"

helloFunction() {
    messageFunction() {
        echo $1
    }
    messageFunction "This is Hello Function!"
    len=`ls -aghl | wc -c`
    ls -aghl /
    # echo $len
    if [ 1 -lt 2 -a -n $len ];
    then
        solution=`expr 1 + 1`
        echo "This is 1+1=$solution"
    fi
}

helloFunction