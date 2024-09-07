#!/bin/bash

# Check if there is a SSH_KEY_NAME variable without a number
if [ -n "$SSH_KEY_NAME" ]; then
    # Add this variable to the list
    export SSH_KEY_NAME0="$SSH_KEY_NAME"
    export TUNNEL_USER0="$TUNNEL_USER"
    export TUNNEL_IP0="$TUNNEL_IP"
    export LOCAL_PORT0="$LOCAL_PORT"
    export REMOTE_PORT0="$REMOTE_PORT"
    export URL_FOR_TUNNEL0="$URL_FOR_TUNNEL"
fi

# Get a list of environment variables with SSH_KEY_NAME and their numbers
ssh_key_names=$(env | grep SSH_KEY_NAME | grep -o '[0-9]\+' | sort -u)

# Array to store PIDs of background processes
pid_list=()

# Loop through all the numbers and start SSH tunnels
for ssh_number in $ssh_key_names; do
    echo "[INFO] Starting SSH Tunnel for SSH_KEY_NAME$ssh_number"
    # Forming the names of environment variables
    ssh_key_var="SSH_KEY_NAME$ssh_number"
    tunnel_user_var="TUNNEL_USER$ssh_number"
    tunnel_ip_var="TUNNEL_IP$ssh_number"
    local_port_var="LOCAL_PORT$ssh_number"
    remote_port_var="REMOTE_PORT$ssh_number"
    url_for_tunnel_var="URL_FOR_TUNNEL$ssh_number"

    # Get the values of the variables
    ssh_key_name="${!ssh_key_var}"
    tunnel_user="${!tunnel_user_var}"
    tunnel_ip="${!tunnel_ip_var}"
    local_port="${!local_port_var}"
    remote_port="${!remote_port_var}"
    url_for_tunnel="${!url_for_tunnel_var}"


    echo "[SSH Key Name] = $ssh_key_name"
    echo "[SSH Tunnel User] = $tunnel_user"
    echo "[SSH Tunnel IP] = $tunnel_ip"
    echo "[SSH Tunnel Local Port] = $local_port"
    echo "[SSH Tunnel Remote Port] = $remote_port"
    echo "[SSH Tunnel URL Remote ] = $url_for_tunnel"

    # Start SSH Tunnel
    ssh -i "/ssh-keys/$ssh_key_name" \
        -vvv -o ServerAliveInterval=30 -o ServerAliveCountMax=5 \
        -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
        "$tunnel_user@$tunnel_ip" -N -L "*:$local_port:$url_for_tunnel:$remote_port" >"ssh-tunnel-$ssh_number.log" 2>&1 &

    # Список PID запущенных процессов
    pid_list+=($!)
    echo "[STARTED] SSH Tunnel started with pid=$!"

    # Sleep for a short duration before starting the next tunnel
    sleep 1
done

# Maximum waiting time for loop
WAIT_TIMEOUT=10

# Wait for all background processes to start
for pid in "${pid_list[@]}"; do
    echo "Waiting for SSH Tunnel with PID $pid to start..."
    # Initialize the timer
    start_time=$(date +%s)
    # Wait until the process starts or times out
    while [ ! -d "/proc/$pid" ]; do
        current_time=$(date +%s)
        if ((current_time - start_time >= WAIT_TIMEOUT)); then
            echo "Timed out waiting for SSH Tunnel with PID $pid to start" >&2
            for ssh_number in $ssh_key_names; do
              cat "ssh-tunnel-$ssh_number.log" >&2
            done
            exit 1
        fi
        sleep 1
    done
done

# Loop through all PIDs in the list
for pid in "${pid_list[@]}"; do
    # Check for the presence of the /proc/$pid directory
    if [ -d "/proc/$pid" ]; then
        echo "SSH Tunnel with PID $pid is running."
    else
        echo "Failed to start SSH Tunnel with PID $pid" >&2
        for ssh_number in $ssh_key_names; do
          cat "ssh-tunnel-$ssh_number.log" >&2
        done
        exit 1
    fi
done

# Keep the script running to keep the container alive
tail -f /dev/null