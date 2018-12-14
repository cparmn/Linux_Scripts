#!/bin/bash
#Made for Joining Linux Servers to domains 

#Create by Casey Parman
#Its probably Broken, so good luck.
#Version 0.1 6/15/2018
#Creating and running the script

#Currently only Allows group linuxadmins to log in and perform SUDO 

# chmod +x domain.sh 
# ./domain.sh 

if [[ $(id -u) -ne 0 ]]
	then echo "Please run as root"
	exit 10
else 
	#Install Required Software
	yum -y install realmd samba samba-common oddjob oddjob-mkhomedir sssd ntpdate ntp
	#Setup NTP
	echo -n "Enter FQDN for time server:"
	read FQDN_TIME
	systemctl enable ntpd.service 
	ntpdate  $FQDN_TIME
	systemctl restart ntpd.service 

	echo -n "Enter Hostname:"
	read HNAME
	echo "Updating Hostname"
	hostname $HNAME
	sed -i -e 's/.*/'$HNAME'/g' /etc/hostname
	hostnamectl set-hostname $HNAME
	hostnamectl status

	echo -n "Enter Domain to Join:"
	read DOMAIN

	#Joining Domain
	echo "Checking Domain"
	grep $DOMAIN /etc/sssd/sssd.conf > /dev/null 2>&1
	if [ $? != 0 ]
	then
		echo "Joining Domain"
		echo -n "Enter Domain Admin Account:"
		read DNAME
		echo -n "Enter OU for Computer:<OU=Servers,DC=domain,DC=org>"
		read OU
		echo -n "Enter LDAP User Search Base: <OU=_Users,DC=domain,DC=org>"
		read LSBASE
		echo -n "Enter LDAP Group Search Base: <OU=Linux,OU=Administration,OU=Security Groups,DC=domain,DC=org>"
		read GSEARCH
		echo -n "Enter Domain to Join:"
		read DOMAIN

		realm join -U $DNAME -v --computer-ou=$OU $DOMAIN
		if [ $? = 0 ]
		then
			echo "Computer Joined to Domain"
			sed -i -e 's/\/home\/%u@%d"/"\/home\/%u/g' /etc/sssd/sssd.conf
			sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf
			echo "ldap_search_base = $OU" >> /etc/sssd/sssd.conf
			echo "ldap_group_search_base = $GSEARCH" >> /etc/sssd/sssd.conf
			echo "AllowGroups linuxadmins" >> /etc/ssh/sshd_config
			systemctl restart sshd
			##SUDO Changes##
			cp /etc/sudoers /etc/sudoers.new
			echo "##Allow AD Admins To sudo" >> /etc/sudoers.new
			echo "%linuxadmins  ALL=(ALL)     ALL" >> /etc/sudoers.new
			visudo -q -c -s -f /etc/sudoers.new
			if [ $? = 0 ]
			then
				mv /etc/sudoers /etc/sudoers.old
				mv /etc/sudoers.new /etc/sudoers
			fi
			systemctl restart sssd
		else
			echo $?
			echo "Could not Join domain, Continue Manually"
			exit 1
		fi
		systemctl restart sssd
	else
		echo "Already Joined to $DOMAIN"
	fi


	#updating system
	echo "updating system"
	yum -y install cifs-utils.x86_64
	yum -y install sysstat 
	yum -y update
fi

exit 0

