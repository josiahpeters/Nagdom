start "filebeat iis" cmd /c "filebeat.exe -e -c filebeat.iis.yml"
start "filebeat app" cmd /c "filebeat.exe -e -c filebeat.app.yml"