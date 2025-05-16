#!/bin/bash

# 0. Navigate to a temporary directory
cd /tmp || { echo "FATAL: Failed to cd to /tmp"; exit 1; }

# 1. Download Firefox
echo "Downloading Firefox..."
# Clean up any previous attempt
rm -f firefox.tar.bz2 firefox # Remove old download and extracted folder
wget -O firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest-ssl&os=linux64&lang=en-US"
if [ $? -ne 0 ]; then
    echo "ERROR: Firefox download failed (wget returned non-zero)."
    exit 1
fi

# Verify download (simple check: is it non-empty?)
if [ ! -s firefox.tar.bz2 ]; then
    echo "ERROR: Downloaded file firefox.tar.bz2 is empty or does not exist."
    exit 1
fi

echo "-----------------------------------------------------"
echo "Downloaded file information:"
ls -l firefox.tar.bz2
echo "Actual file type according to 'file' command:"
file firefox.tar.bz2
echo "-----------------------------------------------------"

# 2. Extract the archive
echo "Extracting Firefox..."
# Use 'tar xf' to auto-detect compression.
# The 'v' flag (verbose) can be added for more detailed output: tar xvf firefox.tar.bz2
tar xf firefox.tar.bz2
EXTRACT_STATUS=$?

if [ ${EXTRACT_STATUS} -ne 0 ]; then
    echo "ERROR: Failed to extract firefox.tar.bz2 (tar returned status ${EXTRACT_STATUS})."
    echo "The file might be corrupted or not a recognized tar archive."
    echo "Please check the 'file' command output above to see what type of file was downloaded."
    # If it claimed to be bzip2, let's test it specifically
    if [[ $(file firefox.tar.bz2) == *"bzip2 compressed data"* ]]; then
        echo "Attempting to test bzip2 integrity directly..."
        bzip2 -tvf firefox.tar.bz2
    fi
    exit 1
fi

# 3. Check if extraction was successful by looking for the 'firefox' directory
if [ ! -d "firefox" ] || [ ! -f "firefox/firefox" ]; then
    echo "ERROR: The 'firefox' directory (or firefox/firefox executable) was not found after extraction."
    echo "The archive may have a different top-level directory structure, or extraction failed to produce the expected output."
    echo "Contents of /tmp after extraction attempt:"
    ls -lA
    exit 1
fi

# 4. Move Firefox to /opt (system-wide installation)
echo "Moving Firefox to /opt/firefox..."
# Remove existing /opt/firefox if it exists, to prevent issues with mv
if [ -d "/opt/firefox" ]; then
    echo "Removing existing /opt/firefox..."
    sudo rm -rf /opt/firefox
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to remove existing /opt/firefox. Check permissions or if it's in use."
        exit 1
    fi
fi
sudo mv firefox /opt/firefox
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to move 'firefox' directory to /opt/firefox."
    exit 1
fi

# 5. Create a symbolic link for command-line access
echo "Creating symbolic link in /usr/local/bin..."
sudo ln -sf /opt/firefox/firefox /usr/local/bin/firefox
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to create symbolic link /usr/local/bin/firefox. You might not be able to run 'firefox' from terminal directly without specifying full path."
fi

# 6. Create a .desktop file for application menu integration
echo "Creating .desktop file..."
# Use sudo with a subshell to handle the redirection securely with cat
sudo bash -c 'cat > /usr/share/applications/firefox-custom.desktop <<EOF
[Desktop Entry]
Name=Firefox (Custom Download)
Comment=Browse the World Wide Web
GenericName=Web Browser
Keywords=Internet;WWW;Browser;Web;Explorer
Exec=/opt/firefox/firefox %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=/opt/firefox/browser/chrome/icons/default/default128.png
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;x-scheme-handler/chrome;video/webm;application/x-xpinstall;
StartupNotify=true
StartupWMClass=Firefox
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=Open a New Window
Exec=/opt/firefox/firefox --new-window

[Desktop Action new-private-window]
Name=Open a New Private Window
Exec=/opt/firefox/firefox --private-window
EOF'
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to create .desktop file. Firefox might not appear in your application menu."
fi

# 7. Update desktop database
echo "Updating desktop database..."
if [ -f "/usr/share/applications/firefox-custom.desktop" ]; then
    sudo update-desktop-database /usr/share/applications/
else
    echo "Skipping update-desktop-database as .desktop file was not created."
fi

# 8. Clean up downloaded file
echo "Cleaning up downloaded archive..."
rm -f firefox.tar.bz2

echo ""
echo "Firefox installation process finished."
if [ -x "/opt/firefox/firefox" ]; then
    echo "Firefox appears to be installed in /opt/firefox."
    echo "You should now be able to launch 'Firefox (Custom Download)' from your application menu or type 'firefox' in the terminal (if symlink was successful)."
else
    echo "Firefox installation may have failed. Please review messages above."
fi
echo "To update, Firefox has a built-in updater (Help > About Firefox)."
echo "If it has permission issues updating /opt/firefox, you'll need to re-run a similar script for the new version or manually replace /opt/firefox."
