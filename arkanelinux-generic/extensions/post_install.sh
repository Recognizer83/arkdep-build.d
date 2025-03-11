#Setting TTY font to Terminus.
if [ -z "$(grep ter-132n /arkdep/overlay/etc/vconsole.conf)" ]; then
	echo 'FONT=ter-132n' | tee -a /arkdep/overlay/etc/vconsole.conf
fi


#Adding my secondary SSD to automount.
if [ -z "$(grep 64f851f7-dab5-44c3-9e69-246c69be13c8 /arkdep/overlay/etc/fstab)" ]; then
	echo '/dev/disk/by-uuid/64f851f7-dab5-44c3-9e69-246c69be13c8 /run/media/user/64f851f7-dab5-44c3-9e69-246c69be13c8 auto nosuid,nodev,nofail,x-gvfs-show,x-gvfs-name=Disk 0 0' | tee -a /arkdep/overlay/etc/fstab
fi


#Removing /var/usrlocal from migrations.
if [ ! -z "$(grep var/usrlocal /arkdep/config)" ]; then
	sed -e "s%'var/usrlocal' %%g" -i /arkdep/config
fi


#Adding Chaotic repo.
arch-chroot $workdir pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
arch-chroot $workdir pacman-key --lsign-key 3056513887B78AEB
arch-chroot $workdir pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
arch-chroot $workdir pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo '
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist ' | arch-chroot $workdir tee -a /etc/pacman.conf


#Installing Paru from Chaotic repo.
arch-chroot $workdir pacman -Syyu --noconfirm paru-git


#Adding temporary user 'aur' to install AUR packages.
arch-chroot $workdir useradd aur -m
arch-chroot $workdir chage -E -1 aur
echo 'password' | arch-chroot $workdir passwd -s aur
echo '
aur ALL=(ALL:ALL) ALL
Defaults:aur !authenticate ' | arch-chroot $workdir tee -a /etc/sudoers


#Using user 'aur' to install necessary AUR packages.
echo 'password\n' | arch-chroot $workdir sudo -S -u aur paru -Syy --noconfirm wezterm-git eww-git bluetuith-bin mmtui-bin calcure xdg-desktop-portal-termfilechooser-hunkyburrito-git quich ncpamixer wl-clipboard-rs


#Cleaning up after package install.
echo 'password\n' | arch-chroot $workdir sudo -S -u aur paru -Scc --noconfirm
echo 'password\n' | arch-chroot $workdir sudo -S -u aur paru -Rns --noconfirm $(echo 'password\n' | arch-chroot $workdir sudo -S -u aur paru -Qtdq)


#Deleting temporary user 'aur'.
arch-chroot $workdir bash -c "cat /etc/sudoers | grep -vF 'aur ALL=(ALL:ALL) ALL' > tmprr && mv -f tmprr /etc/sudoers"
arch-chroot $workdir bash -c "cat /etc/sudoers | grep -vF 'Defaults:aur !authenticate' > tmprr && mv -f tmprr /etc/sudoers"
arch-chroot $workdir userdel -r aur


#Enabling bluetooth.
arch-chroot $workdir systemctl enable bluetooth.service


#Enabling wifi.
arch-chroot $workdir systemctl enable systemd-resolved.service
arch-chroot $workdir systemctl enable iwd.service


#Enabling ADB server.
arch-chroot $workdir systemctl enable adbserver.service


#Making ZSH default shell for root user.
arch-chroot $workdir systemctl enable zshroot.service


#Making yazi wrapper executable.
arch-chroot $workdir systemctl enable xpermprovider.service
