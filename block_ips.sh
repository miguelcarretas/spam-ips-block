#!/bin/bash
#####################################################
#       Autor: Miguel Carretas Perulero             #
#       Description: This script block dangers IP   #
#       and prevent posible attacks                 #
#                                                   #
#####################################################
# ¡¡README!!
#Before executing the script make sure that your public IPv4 address is in the /etc/hosts.allow file, 
#otherwise you will lose connectivity with your machine if you are accessing remotely through the internet.
#
#In order to avoid rare errors, I strongly recommend you to remove all the comment lines that come by default 
#in the file mentioned above (/etc/hosts.allow).
#

file=bad_ips.txt
hosts_allow=/etc/hosts.allow
# First, it checks the file that saves the failed logins, filtering through public IPv4 and redirecting the output to a file.
utmpdump /var/log/btmp | egrep -v "root" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | uniq > $file
cat /var/log/messages | grep "FINAL_REJECT" | awk '{print $10}' | cut -d "=" -f 2 | uniq  >> $file

filter=$file
cat $filter | uniq > $file

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
        let "newip++" # We add +1 to the variable "newip" for each interaction of the while loop
        else
        echo "The IP: $line has already been blocked beforehand." # If public IPv4 is already denied, we display this message
        fi
done < $file

while read line;
do
        firewall-cmd --permanent --remove-rich-rule="rule family='ipv4' source address='$line' reject"
done < $hosts_allow

echo -e
echo "Restarting firewallcmd service"
systemctl restart firewalld.service

# Here we show how many new IPv4s have been blocked
echo -e
echo "$newip IP's blocked"
echo -e

# Here we show how many IPv4s are blocked in total

totalips=`cat $file | wc -l`
echo -e
echo "$totalips bad IP's register"

echo "********** The program is finished *************"
