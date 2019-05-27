FROM nexus.bancopan.com.br:5000/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019
LABEL MAINTAINER="Andre Faria <andre.faria@grupopan.com>"

# Install chocolatey
RUN powershell -Command \ 
    Set-ExecutionPolicy Bypass -Scope Process -Force ; \
    Invoke-Expression -Command ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Install packages
RUN powershell -Command \
    choco install -y git jdk8 openssh docker-cli              

# Configure openssh
RUN powershell -Command \
    $previousPath = $PWD.Path ; \
    $opensshPath = \"C:\Program Files\OpenSSH-Win64\" ; \
    $path = [System.Environment]::GetEnvironmentVariable(\"PATH\", \"Machine\") ; \
    [System.Environment]::SetEnvironmentVariable(\"PATH\", $path + \";$opensshPath;\", \"Machine\") ; \
    New-Item -Path $env:ProgramData\ssh -ItemType Directory >> temp ; \
    Set-Location -Path \"$opensshPath\" ; \
    Copy-Item -Path sshd_config_default -Destination $env:ProgramData\ssh\sshd_config ; \
    Invoke-Expression -Command \"ssh-keygen.exe -A\" ; \
    .\FixHostFilePermissions.ps1 -Confirm:$false ; \
    .\FixUserFilePermissions.ps1 -Confirm:$false ; \
    .\install-sshd.ps1 ; \
    Set-Service -Name  sshd -StartupType Automatic ; \
    Start-Service -Name sshd ; \
    Set-Location -Path \"$previousPath\" ; \
    New-ItemProperty -Path \"HKLM:\SOFTWARE\OpenSSH\" -Name DefaultShellCommandOption -Value \"/c\" -PropertyType String -Force  >> temp ; \
    New-ItemProperty -Path \"HKLM:\SOFTWARE\OpenSSH\" -Name DefaultShell -Value \"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe\" -PropertyType String -Force >> temp 
    
# Copy entrypoint script
COPY ./entrypoint.ps1 .

# Add root user and set password
RUN powershell -Command \
    $psw = ConvertTo-SecureString -AsPlainText -Force -String \"lJe2u2P+iMk0lyCNHsEM39Sxe0+0R+x6Urkdhno5ffw=\" ; \
    New-LocalUser -Name \"root\" -Password $psw -FullName \"Root user\" -Description \"User for Jenkins pipeline automation\" -AccountNeverExpires -PasswordNeverExpires >> temp ; \
    Add-LocalGroupMember -Group \"Administrators\" -Member \"root\"

EXPOSE 22

ENTRYPOINT powershell -Command .\entrypoint.ps1
