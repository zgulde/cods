#!/usr/bin/env bash

set -e

random_sleep_time=$(($RANDOM % 60))
random_sleep_time="${random_sleep_time}m"

sleep $random_sleep_time
/usr/bin/letsencrypt renew --non-interactive --agree-tos --email {{email}}
systemctl restart nginx
