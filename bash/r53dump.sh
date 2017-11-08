#bin/bash
# Dumps list of all Route53 zones in an AWS account
# Requires cli53 https://github.com/barnybug/cli53
# Usage ./r53dump.sh <aws profile name>
#

profile=$1

ZONES=`cli53 list --profile $profile | grep -Po 'Id: "\/hostedzone\/\K[^"]*'`

for z in $ZONES
do
cli53 export $z --profile $profile
done
