sudo rm /tmp/*
./bin/trema killall --all
sudo ovs-vsctl del-br br0x1
sudo ip netns delete host1
sudo ip netns delete host2

