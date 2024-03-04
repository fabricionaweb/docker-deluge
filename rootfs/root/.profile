# ~/.profile: executed by Bourne-compatible login shells.

# export network variables to be used with wg-quick
dockernet="$(ip route show default)"
export WG_DEV="wg0"
export BR_DEV="$(echo $dockernet | awk '{print $5}')"

export BR_GATEWAY="$(echo $dockernet | awk '{print $3}')"
export BR_CIDR="$(ip -o addr show $BR_DEV | awk '{print $4}')"
export LAN_IP="${BR_CIDR%/*}"
