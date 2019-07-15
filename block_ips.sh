#!/bin/bash
#####################################################
#       Autor: Miguel Carretas Perulero             #
#       Description: This script block dangers IP   #
#       and prevent posible attacks                 #
#                                                   #
#####################################################
file=bad_ips.txt

# First, it checks the file that saves the failed logins, filtering through public IPv4 and redirecting the output to a file.
utmpdump /var/log/btmp | egrep -v "root" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | uniq > $file

echo "********** Start spam IP's block program *************"
echo -e

echo "Checking existing firewalls rules..."
echo -e

# We check existing rules to NOT overwrite them

firewall_rules="rules.txt"
echo "" > $firewall_rules
iptables -L -n > $firewall_rules

# Initialize "newip" variable
newip=0

while read line;
do
        if [ `cat $firewall_rules | grep $line | grep "REJECT" | wc -l` -eq 0  ]; then # If the public IPv4 is not denied, we add the new rule
        firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='$line' reject"
        newip=`expr $newip+1` # We add +1 to the variable "newip" for each interaction of the while loop
        else
        echo "The IP: $line has already been blocked beforehand." # If public IPv4 is already denied, we display this message
        fi
done < $file

echo "Restarting firewallcmd service"
systemctl restart firewalld.service

# Here we show how many new IPv4s have been blocked

echo "$newip IP's blocked"
echo -e

# Here we show how many IPv4s are blocked in total

totalips=`cat $file | wc -l`
echo -e
echo "$totalips bad IP's register"

echo "********** The program is finished *************"
