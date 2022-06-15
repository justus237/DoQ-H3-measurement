#!/bin/bash
if [[ $EUID -ne 0 ]]; then
    echo "$0 is not running as root. Try using sudo."
    exit 2
fi


echo "website_under_test=www.example.org" > website-under-test

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_dsl.sh
echo "##DSL: 42.35979ms"
bash ./test_rtt.sh
sleep 5

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_cable.sh
echo "##Cable: 25.17665ms"
bash ./test_rtt.sh
sleep 5

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_fixed_fiber.sh
echo "##Fiber: 14.767147ms"
bash ./test_rtt.sh
sleep 5

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_4g.sh
echo "##4G: 91.85231065904635ms"
bash ./test_rtt.sh
sleep 5

bash ./setup_measurement.sh >> setup.log 2>&1
bash ./tc_netem_4g_medium.sh
echo "##4G medium: 104.5041425140391ms"
bash ./test_rtt.sh
