#!/bin/zsh
# Michael Oliver mcoliver.com
############################
# setup a Lightsail server #
############################

KEYPAIRFILE='~/.ssh/id_rsa.pub'
KEYPAIRNAME=$(basename -s '.pub' ${KEYPAIRFILE})
MACHINENAME='wg001'
OS='ubuntu_22_04'
PORT='41194'
REGION='ap-south-1'

# upload keypair
aws lightsail import-key-pair \
    --region ${REGION} \
    --key-pair-name ${KEYPAIRNAME} \
    --public-key-base64 $(base64 -i ${KEYPAIRFILE})

# Get the cheapest bundle
CHEAPBUNDLE=$(echo `aws lightsail get-bundles --query 'bundles[0].bundleId' --region ${REGION} --output text` | tr -d '"')

# Create the instance
aws lightsail create-instances \
    --instance-names ${MACHINENAME} \
    --availability-zone  "${REGION}" \
    --blueprint-id ${OS} \
    --bundle-id ${CHEAPBUNDLE} \
    --key-pair-name ${KEYPAIRNAME}

# Wait a minute then grab the IP
EXTERNALIP=$(aws lightsail get-instance-access-details --instance-name ${MACHINENAME} --query 'accessDetails.ipAddress' --output text)

# Configure Lightsail Firewall.
# Can also use `open-instance-public-ports --port-info` if you want to add to the rules not remove the defaults
aws lightsail put-instance-public-ports \
    --instance-name ${MACHINENAME} \
    --region ${REGION} \
    --port-infos '[{"fromPort": 41194, "toPort": 41194, "protocol": "udp"}, {"fromPort": 22, "toPort": 22, "protocol": "tcp"}]'

# Print out the IP so we can ssh to it
echo $EXTERNALIP

#Don't forget to stop / delete it
# aws lightsail delete-instance --region ${REGION} --instance-name ${MACHINENAME}
# aws lightsail stop-instance --region ${REGION} --instance-name ${MACHINENAME}