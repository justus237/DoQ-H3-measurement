#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi


echo "website_under_test=${curr_website}" > website-under-test
bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_dsl.sh
echo "42.35979ms"
bash ./test_rtt.sh

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_cable.sh
echo "25.17665ms"
bash ./test_rtt.sh

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_fiber.sh
echo "14.767147ms"
bash ./test_rtt.sh

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_4g.sh
echo "91.85231065904635ms"
bash ./test_rtt.sh

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_4g_medium.sh
echo "104.5041425140391ms"
bash ./test_rtt.sh
