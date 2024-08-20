FROM debian:stable

RUN apt-get update && apt-get upgrade -y && apt-get install -y samba

# Copy the entrypoint script into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["/usr/sbin/smbd", "--foreground", "--no-process-group"]

EXPOSE 139 445
