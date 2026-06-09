# Prints Google Sign-In values to register in Google Cloud Console.
$sha1 = & keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android 2>$null |
    Select-String 'SHA1:' | ForEach-Object { ($_ -replace '.*SHA1:\s*', '').Trim() }

Write-Host ''
Write-Host '========== GOOGLE SIGN-IN SETUP (Android) ==========' -ForegroundColor Cyan
Write-Host 'Package name : com.sync.sync_app'
Write-Host "SHA-1 debug  : $sha1"
Write-Host 'Web client   : 366172488368-4brct5chejltaa6rlk42b0pnn2a53skr.apps.googleusercontent.com'
Write-Host 'Android cli. : 366172488368-n76f7r1ab2joffko6cvf2b3564togekv.apps.googleusercontent.com'
Write-Host ''
Write-Host '1) Open: https://console.cloud.google.com/apis/credentials?project=366172488368'
Write-Host '2) Edit OAuth client type ANDROID (not Web)'
Write-Host '3) Package = com.sync.sync_app , SHA-1 = line above , click SAVE'
Write-Host '4) OAuth consent screen -> Test users -> add your Gmail'
Write-Host '5) Wait 5 min, clear Google Play Services cache on phone, flutter run again'
Write-Host '====================================================' -ForegroundColor Cyan
Write-Host ''
