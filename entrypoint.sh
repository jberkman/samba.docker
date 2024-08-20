#!/bin/bash
set -e

# Update package list and upgrade installed packages
apt-get update && apt-get upgrade -y

mkdir -vp /etc/samba/private/
cp -va /etc/host/smbpasswd /etc/samba/private/

# Check /etc/samba/private/smbpasswd and sync users from /etc/host
if [ -f /etc/samba/private/smbpasswd ]; then
  while IFS=: read -r smb_user _; do
    # Sync user from /etc/host/passwd
    if [ -f /etc/host/passwd ]; then
      while IFS=: read -r user x uid gid _; do
        if [ "$user" == "$smb_user" ]; then
          if ! id -u "$user" >/dev/null 2>&1; then
            echo "useradd -u $uid -g $gid -m $user"
            useradd -u "$uid" -g "$gid" -m "$user"
          else
            echo "usermod -u $uid -g $gid $user"
            usermod -u "$uid" -g "$gid" "$user"
          fi
        fi
      done < /etc/host/passwd
    fi

    # Sync group from /etc/host/group
    if [ -f /etc/host/group ]; then
      while IFS=: read -r group x gid users; do
        # Add user to supplemental groups if they are a member
        IFS=',' read -ra group_users <<< "$users"
        for group_user in "${group_users[@]}"; do
          if [ "$group_user" == "$smb_user" ]; then
            if ! getent group "$gid" >/dev/null 2>&1; then
              echo "groupadd -g $gid $group"
              groupadd -g "$gid" "$group"
            else
              group=$(getent group "$gid" | cut -d: -f1)
            fi
            echo "usermod -aG $group $smb_user"
            usermod -aG "$group" "$smb_user"
          fi
        done
      done < /etc/host/group
    fi

    # Copy password from /etc/host/shadow
    if [ -f /etc/host/shadow ]; then
      while IFS=: read -r user password _; do
        if [ "$user" == "$smb_user" ]; then
          if id -u "$user" >/dev/null 2>&1; then
            echo "usermod -p '********' $user"
            usermod -p "$password" "$user"
          fi
        fi
      done < /etc/host/shadow
    fi
  done < /etc/samba/private/smbpasswd
fi

# Execute the CMD
exec "$@"
