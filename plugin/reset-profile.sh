#!/bin/bash
profile="$HOME/.analytics_profile"
uid=$(cat $profile)
curl -X POST -F "id=$uid" http://localhost:4444/reset-profile/
