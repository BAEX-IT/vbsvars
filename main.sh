#!/usr/bin/bash

func() {
    echo Hello!
}

# MAINTENANCE

dropcaches() {
    sync && echo 3 > /proc/sys/vm/drop_caches
}

"$@"
