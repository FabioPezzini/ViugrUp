#!/bin/bash

bridge=$1
namespace=$2
addr=$3

vethA=veth-$namespace
vethB=eth0

sudo ip netns add $namespace
sudo ip link add $vethA type veth peer name $vethB

sudo ip link set $vethB netns $namespace
sudo ip netns exec $namespace ip addr add $addr dev $vethB
sudo ip netns exec $namespace ip link set $vethB up

sudo ip link set $vethA up

sudo brctl addif $bridge $vethA
