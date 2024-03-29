#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi

declare -a websites=("www.example.org" "www.wikipedia.org" "www.instagram.com")

while true
do
    for curr_website in "${websites[@]}"
    do
        echo "website_under_test=${curr_website}" > website-under-test
        bash ./setup_measurement.sh >> setup.log 2>&1
        bash ./tc_tbf_netem_fixed_average.sh
        bash ./run_measurement.sh
    done
done