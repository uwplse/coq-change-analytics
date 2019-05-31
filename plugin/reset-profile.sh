#!/bin/bash
profile="$HOME/.analytics_profile"
uid=$(cat $profile)
curl -X POST -F "id=$uid" http://ec2-18-225-35-143.us-east-2.compute.amazonaws.com:44/reset-profile/
