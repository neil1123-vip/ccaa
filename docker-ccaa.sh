#!/bin/sh
#####	一键安装File Browser + Aria2 + AriaNg		#####
#####	作者：xiaoz.me						#####
#####	更新时间：2020-02-27				#####
#导入环境变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH
#各种路径设置
master_url='https://github.com/neil1123-vip/ccaa/raw/master/master.zip'
ccaa_web_url='http://soft.xiaoz.org/linux/ccaa_web'
aria2c="/usr/bin/aria2c"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"
#安装前的检查
function check(){
	echo '-------------------------------------------------------------'
	if [ -e "/etc/ccaa" ]
        then
        echo 'CCAA已经安装，若需要重新安装，请先卸载再安装！'
        echo '-------------------------------------------------------------'
        exit
	else
	        echo '检测通过，即将开始安装。'
	        echo '-------------------------------------------------------------'
	fi
}
#安装之前的准备
function setout(){
	#安装需要的软件
	apk add curl wget zip tar bzip2 unzip findutils jq bash
	#创建临时目录
	cd
	mkdir ./ccaa_tmp
}
#安装Aria2
function install_aria2(){
	#进入临时目录
	cd ./ccaa_tmp
	#安装aria2静态编译版本，来源于https://github.com/P3TERX/aria2-builder/
	aria2_new_ver=$(
        {
            wget -t2 -T3 -qO- "https://api.github.com/repos/P3TERX/aria2-builder/releases/latest" ||
                wget -t2 -T3 -qO- "https://gh-api.p3terx.com/repos/P3TERX/aria2-builder/releases/latest"
        } | grep -o '"tag_name": ".*"' | head -n 1 | cut -d'"' -f4
    )

	DOWNLOAD_URL="https://github.com/P3TERX/aria2-builder/releases/download/${aria2_new_ver}/aria2-${aria2_new_ver%_*}-static-linux-amd64.tar.gz"
    {
        wget -t2 -T3 -O- "${DOWNLOAD_URL}" ||
            wget -t2 -T3 -O- "https://gh-acc.p3terx.com/${DOWNLOAD_URL}"
    } | tar -zx
    mv -f aria2c "${aria2c}"
    [[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 主程序安装失败！" && exit 1
    chmod +x ${aria2c}
    echo -e "${Info} Aria2 主程序安装完成！"
	cd
}
#安装File Browser文件管理器
function install_file_browser(){
    filebrowser_new_ver=$(wget -t2 -T3 -qO- "https://github.com/filebrowser/filebrowser/releases/latest" | grep -o '<title>Release.*' | head -n 1 | awk '{print $2}')
    filebrowser_url="https://github.com/filebrowser/filebrowser/releases/download/${filebrowser_new_ver}/linux-amd64-filebrowser.tar.gz"
	cd ./ccaa_tmp
	#下载File Browser
	wget ${filebrowser_url}
	#解压
	tar -zxvf linux-amd64-filebrowser.tar.gz
	#移动位置
	mv filebrowser /usr/sbin
	echo -e "${Info} File Browser文件管理器安装完成！"
	cd
}
#处理配置文件
function dealconf(){
	cd ./ccaa_tmp
	#下载CCAA项目
	wget ${master_url}
	#解压
	unzip master.zip
	#下载Aria2附加功能
	PROFILE_URL1="https://p3terx.github.io/aria2.conf"
    PROFILE_URL2="https://aria2c.now.sh"
    PROFILE_URL3="https://gh.p3terx.workers.dev/aria2.conf/master"
    PROFILE_LIST="
clean.sh
core
script.conf
rclone.env
upload.sh
delete.sh
dht.dat
dht6.dat
move.sh
LICENSE
"
    cd ccaa-master/ccaa_dir
    for PROFILE in ${PROFILE_LIST}; do
        [[ ! -f ${PROFILE} ]] && rm -rf ${PROFILE}
        wget -N -t2 -T3 ${PROFILE_URL1}/${PROFILE} ||
            wget -N -t2 -T3 ${PROFILE_URL2}/${PROFILE} ||
            wget -N -t2 -T3 ${PROFILE_URL3}/${PROFILE}
        [[ ! -s ${PROFILE} ]] && {
            echo -e "${Error} '${PROFILE}' 下载失败！清理残留文件..."
            exit 1
        }
    done
    cd
	#复制CCAA核心目录
	cd ./ccaa_tmp
	mv ccaa-master/ccaa_dir /etc/ccaa
	#创建aria2日志文件
	touch /var/log/aria2.log
	touch /var/log/ccaa_web.log
	touch /var/log/fbrun.log
	#upbt增加执行权限
	chmod +x /etc/ccaa/*.sh
	chmod +x /etc/ccaa/core
	chmod +x ccaa-master/ccaa
	cp ccaa-master/dccaa /usr/sbin
	chmod +x /usr/sbin/dccaa
	cd
}
#设置账号密码
function setting(){
	cd
	cd ./ccaa_tmp
	echo '-------------------------------------------------------------'
	#获取ip
	osip=$(curl -4s https://api.ip.sb/ip)
	#执行替换操作
	downpath='/data/ccaaDown'
	aria2_conf_dir='/etc/ccaa'
	mkdir -p ${downpath}
	sed -i "s%dir=%dir=${downpath}%g" /etc/ccaa/aria2.conf
	sed -i "s@/root/.aria2/@${aria2_conf_dir}/@" ${aria2_conf_dir}/*.conf
	sed -ir "s/rpc-secret=.*/rpc-secret=$PASS/g" /etc/ccaa/aria2.conf
	sed -i "s@^#\(retry-on-.*=\).*@\1true@" /etc/ccaa/aria2.conf
	sed -i "s@^\(max-connection-per-server=\).*@\132@" /etc/ccaa/aria2.conf
	#替换filebrowser读取路径
	sed -i "s%ccaaDown%${downpath}%g" /etc/ccaa/config.json
	#替换AriaNg服务器链接
	#sed -i "s/server_ip/${osip}/g" /etc/ccaa/AriaNg/index.html
	#更新tracker
	sh /etc/ccaa/upbt.sh
	#安装AriaNg
	wget ${ccaa_web_url}
	cp ccaa_web /usr/sbin/
	chmod +x /usr/sbin/ccaa_web
	#启动服务
	#nohup aria2c --conf-path=/etc/ccaa/aria2.conf > /var/log/aria2.log 2>&1 &
	#nohup caddy -conf="/etc/ccaa/caddy.conf" > /etc/ccaa/caddy.log 2>&1 &
	#nohup /usr/sbin/ccaa_web > /var/log/ccaa_web.log 2>&1 &
	#运行filebrowser
	#nohup filebrowser -c /etc/ccaa/config.json > /var/log/fbrun.log 2>&1 &
	echo '-------------------------------------------------------------'
	echo "大功告成，请访问: http://${osip}:6080/"
	echo 'File Browser 用户名:ccaa'
	echo 'File Browser 密码:admin'
	echo 'Aria2 RPC 密钥:' $PASS
	echo '帮助文档: https://dwz.ovh/ccaa （必看）' 
	echo '-------------------------------------------------------------'
}
#清理工作
function cleanup(){
	cd
	rm -rf ccaa_tmp
	#rm -rf *.conf
	#rm -rf init
}
#卸载
function uninstall(){
	wget -O ccaa-uninstall.sh https://raw.githubusercontent.com/helloxz/ccaa/master/uninstall.sh
	sh ccaa-uninstall.sh
}
#选择安装方式
echo "------------------------------------------------"
echo "Linux + File Browser + Aria2 + AriaNg一键安装脚本(CCAA)"
echo "1) 安装CCAA"
echo "2) 卸载CCAA"
echo "3) 更新bt-tracker"
echo "q) 退出！"
#read -p ":" istype
case $1 in
    'install') 
    	check
    	setout
    	install_aria2 && \
    	install_file_browser && \
    	dealconf && \
    	setting && \
    	cleanup
    ;;
    'uninstall') 
    	uninstall
    ;;
    'upbt') 
    	sh /etc/ccaa/upbt.sh
    ;;
    'q') 
    	exit
    ;;
    *) echo '参数错误！'
esac
