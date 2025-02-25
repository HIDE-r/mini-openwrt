FROM archlinux
LABEL maintainer=lkangn.collin@gmail.com

# 修改下载源
RUN echo -e 'Server = https://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch\n \
Server = http://mirrors.ustc.edu.cn/archlinux/$repo/os/$arch\n \
Server = https://mirror.xtom.com.hk/archlinux/$repo/os/$arch\n \
Server = http://mirrors.bfsu.edu.cn/archlinux/$repo/os/$arch\n \
Server = http://mirror.xtom.com.hk/archlinux/$repo/os/$arch\n' > /etc/pacman.d/mirrorlist

# 参考: https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
RUN pacman -Sy --noconfirm --needed base-devel autoconf automake bash binutils bison \
bzip2 fakeroot file findutils flex gawk gcc gettext git grep groff \
gzip libelf libtool libxslt m4 make ncurses openssl patch pkgconf \
python rsync sed texinfo time unzip util-linux wget which zlib \
&& pacman -S --noconfirm --needed asciidoc help2man intltool perl-extutils-makemaker swig

# 开发工具
RUN pacman -S --noconfirm vim remake
