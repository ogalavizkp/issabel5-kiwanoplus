#!/bin/bash
# Based on SAM's Elastix 4 on CentOS 7 Installation and Build Script

BLA_metro=( 0.2 '[    ]' '[=   ]' '[==  ]' '[=== ]' '[ ===]' '[  ==]' '[   =]' )

declare -a BLA_active_loading_animation

BLA::play_loading_animation_loop() {
  while true ; do
    for frame in "${BLA_active_loading_animation[@]}" ; do
      printf "\r%s" "${frame}"
      sleep "${BLA_loading_animation_frame_interval}"
    done
  done
}

BLA::start_loading_animation() {
  BLA_active_loading_animation=( "${@}" )
  # Extract the delay between each frame from array BLA_active_loading_animation
  BLA_loading_animation_frame_interval="${BLA_active_loading_animation[0]}"
  unset "BLA_active_loading_animation[0]"
  tput civis # Hide the terminal cursor
  BLA::play_loading_animation_loop &
  BLA_loading_animation_pid="${!}"
}

BLA::stop_loading_animation() {
  kill "${BLA_loading_animation_pid}" &> /dev/null
  printf "\n"
  tput cnorm # Restore the terminal cursor
  reset
}

#trap BLA::stop_loading_animation SIGINT

function generate_files
{
cat > /tmp/inst1.txt <<EOF
httpd
httpd-tools
mariadb
mariadb-connector-c
mariadb-connector-odbc
mariadb-server
php
php-bcmath
php-cli
php-common
php-gd
php-IDNA_Convert
php-imap
php-jpgraph
php-magpierss
php-mbstring
php-mcrypt
php-mysqlnd
php-pdo
php-pear
php-pear-DB
php-PHPMailer
php-process
php-simplepie
php-Smarty
php-soap
php-tcpdf
php-tidy
php-xml
asterisk$ASTVER
asterisk$ASTVER-devel
asterisk$ASTVER-curl
asterisk-codec-g729
asterisk-perl
asterisk-es-sounds
asterisk-fr-sounds
asterisk-sounds-en-gsm
asterisk-pt_BR-sounds
certbot
vim
jq
whois
bind-utils
dhcp-server
langpacks-es
langpacks-en
langpacks-pt
langpacks-pt_BR
langpacks-fa
langpacks-fr
mailx
EOF

cat > /tmp/inst2.txt <<EOF
issabel-geoip
issabel
issabel-prosody-auth
issabel-endpointconfig2
xtables-addons
RoundCubeMail
php-ioncubeloader
libnsl
fop2
EOF
}

function settings
{
  if [ ! "$TERM" = "xterm-256color" ]
  then 
    export NCURSES_NO_UTF8_ACS=1
  fi
  BACKTITLE="Issabel 5 netinstall"
  #Shut off SElinux & Disable firewall if running.
  setenforce 0 &>/dev/null
  sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config

  # Some distros may already ship with an existing asterisk group. Create it here
  # if the group does not yet exist (with the -f flag).
  /usr/sbin/groupadd -f -r asterisk &>/dev/null

  # At this point the asterisk group must already exist
  if ! grep -q asterisk: /etc/passwd ; then
      echo -e "Adding new user asterisk..."
      /usr/sbin/useradd -r -g asterisk -c "Asterisk PBX" -s /bin/bash -d /var/lib/asterisk asterisk &>/dev/null
  fi

  echo -en "        Installing base packages "
  BLA::start_loading_animation "${BLA_metro[@]}"
  yum -y install issabel-config_helpers &> /dev/null
  BLA::stop_loading_animation
  echo -e "\n"
}

function welcome
{
  echo "welcome" >>/tmp/netinstall.log
  dialog --stdout --sleep 2 --backtitle "$BACKTITLE" \
         --infobox " O @ @\n @ @ O\n @ O O\n   O\nIssabel" \
        7 11
}

function sel_astver
{
  ASTVER=$(dialog --no-items --backtitle "$BACKTITLE" \
           --radiolist "Select Asterisk version:" 10 40 2 \
           16  on \
           18  off \
           3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]
  then
    dialog --stdout --sleep 3 --backtitle "$BACKTITLE" \
           --infobox "Install cancelled by user\n\n:(" \
          7 31
    clear
    cleanup
    exit
  fi
}

function add_repos
{
cat > /etc/yum.repos.d/Issabel.repo <<EOF
[issabel-base]
name=Base RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=4&arch=\$basearch&repo=base
#baseurl=http://repo.issabel.org/issabel/4/base/\$basearch/
gpgcheck=0
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-updates]
name=Updates RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=4&arch=\$basearch&repo=updates
#baseurl=http://repo.issabel.org/issabel/4/updates/\$basearch/
gpgcheck=0
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-updates-sources]
name=Updates RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=4&arch=\$basearch&repo=updates
#baseurl=http://repo.issabel.org/issabel/4/updates/SRPMS/
gpgcheck=0
enabled=0
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-beta]
name=Beta RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=4&arch=\$basearch&repo=beta
baseurl=http://repo.issabel.org/issabel/4/beta/\$basearch/
#gpgcheck=1
enabled=0
#gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-extras]
name=Extras RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=4&arch=\$basearch&repo=extras
#baseurl=http://repo.issabel.org/issabel/4/extras/\$basearch/
gpgcheck=1
enabled=0
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel
EOF

cat > /etc/yum.repos.d/Issabel5.repo <<EOF
[issabel-cinco]
name=Base RPM Repository for Issabel 5
mirrorlist=http://mirror.issabel.org/?release=5&arch=\$basearch&repo=base
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-noarch]
name=Base RPM Repository for Issabel 5 (noarch)
mirrorlist=http://mirror.issabel.org/?release=5&arch=noarch&repo=base
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-updates]
name=Updates RPM Repository for Issabel 5
mirrorlist=http://mirror.issabel.org/?release=5&arch=\$basearch&repo=updates
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-updates-noarch]
name=Updates RPM Repository for Issabel 5 (noarch)
mirrorlist=http://mirror.issabel.org/?release=5&arch=noarch&repo=updates
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-extras]
name=Extras RPM Repository for Issabel 5
mirrorlist=http://mirror.issabel.org/?release=5&arch=\$basearch&repo=extras
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-extras-noarch]
name=Extras RPM Repository for Issabel 5 (noarch)
mirrorlist=http://mirror.issabel.org/?release=5&arch=noarch&repo=extras
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel

[issabel-cinco-beta]
name=Beta RPM Repository for Issabel 5
mirrorlist=http://mirror.issabel.org/?release=5&arch=\$basearch&repo=beta
#gpgcheck=1
enabled=0
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel
EOF

cat > /etc/yum.repos.d/commercial-addons.repo <<EOF
[commercial-addons]
name=Commercial-Addons RPM Repository for Issabel
mirrorlist=http://mirror.issabel.org/?release=5&arch=\$basearch&repo=commercial_addons
gpgcheck=1
enabled=1
gpgkey=http://repo.issabel.org/issabel/RPM-GPG-KEY-Issabel
EOF


}

function centos8_tweaks {

ROCKY_VERSION=$(cat /etc/redhat-release | awk '{print $4}' | awk -F. '{print $1}')

echo "centos $ROCKY_VERSION tweaks start" >>/tmp/netinstall.log
grep -qxF 'fastestmirror=True' /etc/dnf/dnf.conf || echo "fastestmirror=True" >> /etc/dnf/dnf.conf
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-${ROCKY_VERSION}.rpm  &>>/tmp/netinstall.log
dnf module enable php:remi-7.4 -y &>>/tmp/netinstall.log
dnf config-manager --set-enabled remi &>>/tmp/netinstall.log
dnf config-manager --set-enabled powertools &>>/tmp/netinstall.log
dnf config-manager --set-enabled devel &>>/tmp/netinstall.log
dnf -y check-upgrade &>>/tmp/netinstall.log
echo "centos $ROCKY_VERSION tweaks end" >>/tmp/netinstall.log
}

function additional_packages
{
  ADDPKGS=""
  OPTS=$(dialog --backtitle "$BACKTITLE" --no-tags \
        --checklist "Choose additional package(s) to install:" 0 0 0 \
        1 "Issabel Network Licensed modules(http://issabel.guru)" on \
        2 "Community Realtime Block List(block SIP attacks from known offenders)" on \
        3 "Sangoma wanpipe drivers" off \
        3>&1 1>&2 2>&3)
  if [ $? -ne 0 ]
  then
    dialog --stdout --sleep 3 --backtitle "$BACKTITLE" \
           --infobox "Install cancelled by user\n\n:(" \
          7 31
    clear
    cleanup
    exit
  fi
  for i in $OPTS
  do
    case $i in
      1)
      ADDPKGS="$ADDPKGS issabel-license webconsole issabel-wizard issabel-packet_capture issabel-upnpc \
      issabel-two_factor_auth issabel-theme_designer issabel-network-agent"
      ;;
      2)
      ADDPKGS="$ADDPKGS issabel-packetbl"
      ;;
      3)
      ADDPKGS="$ADDPKGS wanpipe-utils wanpipe"
      ;;
    esac
  done
}

function yum_gauge
{
  echo "start yum gauge" >>/tmp/netinstall.log
  PACKAGES=$1 #Space separated list of packages.
  TITLE=$2 #Window title
  YUMCMD=$3 #install / update
  dialog --backtitle "$BACKTITLE" --title "$TITLE" --gauge "Installing..." 10 75 < <(
   # Get total number of packages
  n=$(echo $PACKAGES | wc -w); 

   # set counter - it will increase every-time a rpm install
   i=0

   #
   # Start the for loop 
   #
   # read each package from $PACKAGES array 
   # $f has filename 
   for p in $PACKAGES
   do
      # calculate progress
      PCT=$(( 100*(++i)/n ))

      # update dialog box 
cat <<EOF
XXX
$PCT
Installing "$p"...
XXX
EOF
    rpm --quiet -q $p
    if [ $? -ne 0 ] || [ "$YUMCMD" = "update" ]
    then
      if ! yum $BETAREPO --nogpg -y $YUMCMD $p &>>/tmp/netinstall.log
      then
         echo "$p: ERROR installing package" >> /tmp/netinstall_errors.txt
         echo "$p: ERROR installing package" >> /tmp/netinstall.log
      fi
    fi
  done
)
echo "end yum gauge" >>/tmp/netinstall.log
}
function update_os
{
  echo "start update os" >>/tmp/netinstall.log
  PACKAGES=$(yum $BETAREPO -d 0 list updates | tail -n +2 | cut -d' ' -f1) &>>/tmp/netinstall.log
  if [ "$PACKAGES" = "" ]; then
  echo "no package to upgrade" >>/tmp/netinstall.log
  else
      yum_gauge "$PACKAGES" "Yum update" update
  fi
  echo "end update os" >>/tmp/netinstall.log
}

function clean_yum
{
  echo "Cleaning yum" >>/tmp/netinstall.log
  yum clean all &>>/tmp/netinstall.log
}

function install_packages
{
  echo "install packages 1" >>/tmp/netinstall.log
  yum clean all &>>/tmp/netinstall.log
  echo "install packages 2" >>/tmp/netinstall.log
  PACKAGES=$(cat /tmp/inst1.txt)
  echo "install packages 3" >>/tmp/netinstall.log
  yum_gauge "$PACKAGES" "(1/2) Please wait..." install
  echo "install packages 4" >>/tmp/netinstall.log
  PACKAGES=$(cat /tmp/inst2.txt)
  echo "install packages 5" >>/tmp/netinstall.log
  yum_gauge "$PACKAGES $ADDPKGS" "(2/2) Please wait..." install
  echo "install packages 6" >>/tmp/netinstall.log
}

function post_install
{
  (
  systemctl enable mariadb.service
  systemctl start mariadb
  mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('iSsAbEl.2o17')"
  #Shut off SElinux and Firewall. Be sure to configure it in Issabel!
  setenforce 0
  sed -i 's/\(^SELINUX=\).*/\SELINUX=disabled/' /etc/selinux/config
  cp -a /etc/sysconfig/iptables /etc/sysconfig/iptables.org-issabel-"$(/bin/date "+%Y-%m-%d-%H-%M-%S")"
  systemctl enable httpd
  systemctl disable firewalld
  systemctl stop firewalld
  firewall-cmd --zone=public --add-port=443/tcp --permanent
  firewall-cmd --reload
  rm -f /etc/issabel.conf
  mysql -piSsAbEl.2o17 -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('')"

  #patch config files
  echo "noload => cdr_mysql.so" >> /mnt/sysimage/etc/asterisk/modules_additional.conf
  mkdir -p /var/log/asterisk
  mkdir -p /var/log/asterisk/cdr-csv
  mv /etc/asterisk/extensions_custom.conf.sample /etc/asterisk/extensions_custom.conf
  /usr/sbin/amportal chown
  ) &> /dev/null
}

function check_dialog
{
  clear
  echo -en "Looking for dialog..."
  if ! dialog  &> /dev/null
  then
    echo -e "[not found]"
    echo -en "        Installing dialog..."
    BLA::start_loading_animation "${BLA_metro[@]}"
    yum -y install dialog &>/dev/null
    BLA::stop_loading_animation
    echo -e "\n"
    if [ $? -ne 0 ]
    then
      echo -e "\n***yum install dialog FAILED***\n\n"
    fi
    if ! dialog > /dev/null
    then
      echo -e "Dialog is requiered\n"
      exit
    fi
  else
    echo -e "[found]"
  fi
}

function enable_beta()
{
  dialog --title "Are you feeling brave?" --defaultno \
  --backtitle "$BACKTITLE" \
  --yesno "Enable Beta repository?(not recommended for production)" 7 60
  if [ $? -eq 0 ]
  then
      return 0
  fi
  return 1
}

function set_passwords()
{
  /usr/bin/issabel-admin-passwords --init
}

function select_language()
{
  /usr/bin/issabel-change-language
}

function cleanup()
{
(
  rm -f /tmp/inst1.txt
  rm -f /tmp/inst2.txt
  /usr/sbin/amportal chown
) &> /dev/null
}

function bye()
{
  dialog --stdout --sleep 2 --backtitle "$BACKTITLE" --infobox \
"             O @ @\n             @ @ O\n             @ O O\n               O\n            Issabel \n\nRebooting server, log back in in a minute..." \
  10 35
}



function kiwanoplus() {

#instalacion htop

yum install epel-repository
yum -y install dialog
yum -y install epel-release
yum -y install openvpn easy-rsa
yum -y install issabel-developer

name_customer=$(\
      dialog  --backtitle "$BACKTITLE" --title "Ingresa Nombre CLiente Corto para Hostname y descripcion cliente VPN KIWANOPLUS" --no-tags \
          --inputbox "Ingresa nombre de cliente corto para registrar Hostname & Cliente-VPN:" 16 40 \
      3>&1 1>&2 2>&3 3>&- \
    )

hostnamectl set-hostname ippbx-cloud-issa5-"$name_customer"

cd /etc/openvpn
wget https://servicios.kiwano-plus.com/kp_issabel/openvpn-kp/ca.crt --no-check-certificate


dialog --title "INSTALL CERTIFIED FILE VPN" \
       --backtitle "Mensaje de fondo" \
       --msgbox "Por favor, dirigase al servidor KP https://10.0.10.1:10443, debes crear los certificados Openvpn con el nombre:  {ippbx-cloud-issa5-$name_customer}\n Luego, los archivos creados .crt .key colocarlos en el directorio /etc/opevpn/ \n\n Finalice con habilitar y Reinicio servicio:\n ===========================================\n systemctl start openvpn@cloud-ippbxkp-issa-$name_customer\n systemctl enable openvpn@cloud-ippbxkp-issa-$name_customer\n\n" 50 100


yum install htop -y

#instalacion tetlnet
yum install telnet -y

#instalacion sngreep
dnf copr enable irontec/sngrep -y
dnf install sngrep -y

#patch Zona horaria Colombia
sudo sed -i 's/^\;date\.timezone\s*=\s*.*/date.timezone = America\/Bogota/' /etc/php.ini

#patch templatet 
cd /tmp
wget https://servicios.kiwano-plus.com/kp_issabel/theme_issabel_kp.tar.gz --no-check-certificate
tar -xvzf theme_issabel_kp.tar.gz  -C /var/www/html/themes/ && rm -f theme_issabel_kp.tar.gz
chown asterisk:asterisk /var/www/html/themes/kp
sqlite3 /var/www/db/settings.db "update settings set value = 'kp' where value = 'tenant'"

#ajuste SSH 
sed -i 's/#Port 22/Port 58690/g' /etc/ssh/sshd_config

#ajuste SSH 
sqlite3 /var/www/db/acl.db "UPDATE acl_user SET name = 'technicalsupport' WHERE name = 'admin'"

#===================== cambiamos idioma a español
sqlite3 /var/www/db/settings.db "update settings set value = 'es' where value = 'en'" 

#===================== Titulo GUI WEB ISSABEL
user_input2=$(\
  dialog  --backtitle "$BACKTITLE" --title "Ingresa el nuevo Titulo GUI (EJEMPlO: IPPBX CLOUD ASSURE)" --no-tags \
			 --inputbox "Ingresa el nuevo Titulo GUI:" 8 40 \
  3>&1 1>&2 2>&3 3>&- \
)
sed -i 's+<p class="description"></p>+<p class="description">IPPBXKIWANOPLUS '"$user_input2"'</p>+g' /var/www/html/themes/kp/_common/login.tpl
sed -i "s|<title>Issabel - {\$PAGE_NAME}</title>|<title>IPPBXALO '"$user_input2"'</title>|g" /var/www/html/themes/kp/_common/login.tpl
sed -i "s|<title>Issabel</title>|<title>IPPBXKIWANOPLUS '"$user_input2"'</title>|g" /var/www/html/themes/kp/_common/index.tpl


#==================== reducir el margin del logo
sed -i 's|<div class="login-header login-caret">|<div class="login-header login-caret" style="padding:0px">|g' /var/www/html/themes/kp/_common/login.tpl

#=====================  Instalacion fecha actual
rm -f /etc/localtime && ln -s /usr/share/zoneinfo/America/Bogota /etc/localtime  

dialog --title "AVISO" \
       --backtitle "$BACKTITLE" \
       --msgbox "RECUERDE QUE ACCEDE POR SSH CON PUERTO 57690 | USER ISSABEL technicalsupport" 8 50

}


check_dialog
add_repos
settings
welcome
select_language
sel_astver
additional_packages
generate_files
#if enable_beta
#then
#    BETAREPO="--enablerepo=issabel-beta"
#fi
welcome
centos8_tweaks
clean_yum
update_os
install_packages
post_install
set_passwords
kiwanoplus
cleanup
bye
reboot

