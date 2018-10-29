#Created by Tian Xiaodong
#�뽫�ű��ļ�����ΪANSI�����ʽ�������޷�������������ַ���

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

#Global Define
$Global:title = "PowerShell ���˹���"
$Global:version = "1.0.7"

Function Init_power
{
    $warning = "������ʼ���������ʼ�������OK�����������Cancel���˳���`nInitial is coming, press `"OK`" to continue, or press `"Cancel`" to abort."
    $done = "��ʼ����ɣ��뾡��������⡣`nDone, please do the evaluation ASAP."

    $ws = New-Object -ComObject WScript.Shell
    $wsr = $ws.popup($warning,0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( ( $device_count = List_devices ) )
	    {
            1 {
                $list_devices = adb devices

                switch ( ($list_devices) )
                {
                    {($list_devices[1].Contains( ":" ))}{$Console.Text = "Զ���豸�������Գ�ʼ����";break}
                    {($list_devices[1].Contains("unauthorized"))}{$Console.Text = "�豸δ��Ȩ��";break}
                default
                {
                    $init_1 = adb shell dumpsys batterystats --reset
                    $init_2 = adb shell dumpsys batterystats --enable full-wake-history
        
                    if ( ( $init_1 -ne $null ) -or ( $init_2 -ne $null ) )
                    {
                        $Console.Text = [string]$init_1 + "`n" + [string]$init_2
                        $wsi = $ws.popup($done,0,$title,0 + 64)
                    }
                    else
                    {
                        $Console.Text = "��ʼ��ʧ�ܣ������ֻ����ӻ�ADB������"
                    }
                    ;break
                }
               }
              ;break}
            0 {$Console.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Console.Text = "������̫��Android�豸����";break}
        }
    }
    else
    {
        $Console.Text = "��ʼ����ȡ�������ģ�����ɶ��û�ɡ�"
    }
    return
}

Function List_devices
#�����������Ҫ���ദ�жϾ������ú��������н����
#����������Android�豸������������Ϊ���Ρ�
{
    $global:list_devices = adb devices

    if ( $list_devices -ne $null )
    {
        $temp = $null
        $wireless_count = 0
        
        for ( $i = 0;$i -lt $list_devices.Count;$i++ )
        {
            $temp = $temp + $list_devices[$i] + "`n"
            if ( $list_devices[$i].Contains( ":" )  )
            {
                $wireless_count++
            }
        }
        $Console.Text = $temp + "`n��ǰ������ �� + ($list_devices.Count-2) + �� ̨Android�豸��" + "`n���а��� �� + ��$wireless_count�� + �� ̨���������豸��"
        return [int]( $list_devices.Count - 2 )
    }
    else
    {
        $Console.Text = "ִ��ʧ�ܣ�����ADB������"
    }
}

Function Export_bugreport
#���ֻ������һ̨Զ���豸���򲻵�������ΪԶ���豸������Bugreport��Ч��
{
    $temp_dir = Get-Location
    switch ( ( $device_count = List_devices ) )
    {
        1 {
            try
            {
                $list_devices = adb devices

                switch ( ( $list_devices ) )
                {
                    {$list_devices[1].Contains( ":" )}{$Console.Text = "Զ���豸�������Ե�����־��";break}
                    {$list_devices[1].Contains( "unauthorized" )}{$Console.Text = "�豸δ��Ȩ��";break}
                    default
                    {
                        $Console.Text = "���ڵ������˹��̻��ʱ�����ӣ������ĵȴ���`n�������ǰ�����߲��ɵ����"
                        if ( Test-Path bugreport_log )
                        {
                            cd bugreport_log
                        }
                        else
                        {
                            mkdir bugreport_log
                            cd bugreport_log
                        }

                        if ( ( $Get_android_API = adb shell getprop ro.build.version.sdk ) -ge 24 )
                        {
                            adb bugreport
                        }
                        else
                        {
                            $filename = "Bugreport_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".txt"
                            adb bugreport > $filename
                        }

                        $Console.Text = ��������ɣ�`n�� + "Bugreport��־�ļ��Ѵ���ڣ�`n" + ( Get-Location )
                        cd $temp_dir
                        $ws = New-Object -ComObject WScript.Shell
                        $wsi = $ws.popup(��������ɣ���,0,$title,0 + 64)
                        ;break
                    }
                }
            }
            catch [System.Exception]
            {
                $Console.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
            };break
          }
        0 {$Console.Text = "û�ҵ��豸��";break}
        {$_ -ge 2 } {$Console.Text = "������̫���豸����`n����ʱ������ֻ������һ̨Android�豸��";break}
    }
}

Function Run_battery_historian
{
    $temp_dir = Get-Location

    if ( get-process | where-object {$_.Name -eq "battery-historian"} )
    {
	    write-host "Battery-Historian �Ѿ��������ˡ�`n`n����� http://localhost:9999/" -ForegroundColor Red
        $Console.Text = "Battery-Historian �Ѿ��������ˡ�`n`n����� http://localhost:9999/"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("Battery-Historian �Ѿ��������ˡ�`n`n����� http://localhost:9999/",0,"PowerShell ���˹���ϵ��",0 + 64)
        Start-Process -FilePath http://localhost:9999/
    }

    else
    {
        $Console.Text = "Battery Historian �������С�`n����� http://localhost:9999/"
	    $path = Get-Item -Path $env:GOPATH\src\github.com\google\battery-historian
	    
        if ( $path -ne $null )
        {
            cd $path
            Start-Process powershell.exe -ArgumentList "write-host Battery Historian �������У��벻Ҫ�رմ˴��ڡ� -ForegroundColor Yellow `ngo run cmd/battery-historian/battery-historian.go" -WindowStyle Minimized
        }
        else
        {
            $Console.Text = "���߶�ûװ�����и�ë�ߣ�"
        }
        cd $temp_dir
    }
}

Function Show_devices_info
{
    switch ( ( $device_count = List_devices ) )
    {
        1 {
            if ( $list_devices[1].Contains("unauthorized") )
            {    
                $Info.Text = "�豸��δ��Ȩ��"
            }
            else
            {
                try
                {
                    $Get_android_ver = adb shell getprop ro.build.version.release
                    $Get_android_API = adb shell getprop ro.build.version.sdk
                    $Get_screen_res = adb shell wm size
                    $Get_screen_dpi = adb shell wm density
                    $Get_manuf = adb shell getprop ro.product.manufacturer
                    $Get_model = adb shell getprop ro.product.model
                    $Get_CPU = adb shell cat /proc/cpuinfo | findstr "Hardware"
                    $Get_cores = adb shell cat /proc/cpuinfo | findstr "processor"
                    $Get_Mem = adb shell cat /proc/meminfo | findstr "MemTotal"
                    $total_storage, $used_storage, $free_storage = Get_storage
                    $WIFI_stat = adb shell dumpsys wifi
                    $Info.Text = "Android�汾: " + (isNull $Get_android_ver) + "`nAndroid API: " + (isNull $Get_android_API) + "`n��Ļ�ֱ���: " + (isNull $Get_screen_res) + "`n��ĻDPI: " + (isNull $Get_screen_dpi) + "`n������: " + (isNull $Get_manuf) + "`n�ͺ�: " + (isNull $Get_model) + "`nCPU: " + (isNull $Get_CPU).Substring(11) + "`nCPU������: " + $Get_cores.length + "`n�����ڴ�: " + (isNull $Get_Mem).Substring(11).trim() + "`n�ڲ��洢�ռ�: " + $total_storage + "`n���ÿռ�: " + $used_storage + "`nʣ��ռ�: " + $free_storage + "`n" + $WIFI_stat[0]
                }
                catch [System.Exception]
                {
                    $Info.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
                }
            }
            ;break
          }
        0 {$Info.Text = "û�ҵ��豸��";break}
        {$_ -ge 2 } {$Info.Text = "������ô��̨�豸������֪��Ҫ���ĸ���";break}
    }
}

Function Get_storage
{
    $Get_storage = adb shell df /data/

    if ( ( $Get_android_API = adb shell getprop ro.build.version.sdk ) -ge 24 )
    {
        [Math]::Round((($Get_storage[1] -replace "\s{2,}"," ").split(" ")[1]/1024/1024),1).toString() + "GB"
        [Math]::Round((($Get_storage[1] -replace "\s{2,}"," ").split(" ")[2]/1024/1024),1).toString() + "GB"
        [Math]::Round((($Get_storage[1] -replace "\s{2,}"," ").split(" ")[3]/1024/1024),1).toString() + "GB"
    }
    else
    {
        ($Get_storage[2] -replace "\s{2,}"," ").split(" ")[1]
        ($Get_storage[2] -replace "\s{2,}"," ").split(" ")[2]
        ($Get_storage[2] -replace "\s{2,}"," ").split(" ")[3]
    }
}

Function Reboot
{
    $ws = New-Object -ComObject WScript.Shell
    $wsr = $ws.popup("���������豸��ȷ��Ҫ������",0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( ( $device_count = List_devices ) )
        {
            1 {
                $Info.Text = "�������������Ժ�"
                adb reboot
                $Info.Text = "�������������豸��";break
              }
            0 {$Info.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Info.Text = "������̫���豸����û��������";break}
        }       
    }
    else
    {
        $Info.Text = "�úúã��������ˡ�"
    }
}

Function isNull($target)
{
    if ( $target -ne $null )
    {
        return $target
    }
    else
    {
        return "           unknown"
    }
}

Function Connect_devices
{
    $ConnectForm = New-Object System.Windows.Forms.Form
    $ConnectForm.Text = $title
    $ConnectForm.Size = New-Object System.Drawing.Size(300,200) 
    $ConnectForm.StartPosition = "CenterScreen"
    $ConnectForm.SizeGripStyle = "Hide"
    $ConnectForm.MaximizeBox = $false
    $ConnectForm.MinimizeBox = $false
    $ConnectForm.AutoSize = $false
    $ConnectForm.HelpButton = $false
    $ConnectForm.ShowInTaskbar = $false
    $ConnectForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

    $IP = New-Object System.Windows.Forms.TextBox
    $IP.Location = New-Object System.Drawing.Point(15,30) 
    $IP.Size = New-Object System.Drawing.Size(200,20) 
    $IP.ReadOnly = $false
    $IP.Text = ""
    $IP.WordWrap = $false

    $IP_label = New-Object System.Windows.Forms.Label
    $IP_label.Location = New-Object System.Drawing.Point(10,10)
    $IP_label.Size = New-Object System.Drawing.Size(300,20)
    $IP_label.Text = "��������ȷ��ʽ��IP��ַ��"

    $Port_label = New-Object System.Windows.Forms.Label
    $Port_label.Location = New-Object System.Drawing.Point(10,70)
    $Port_label.Size = New-Object System.Drawing.Size(300,20)
    $Port_label.Text = "��������ȷ��ʽ�Ķ˿ںţ���ѡ����"

    $Port = New-Object System.Windows.Forms.TextBox
    $Port.Location = New-Object System.Drawing.Point(15,90) 
    $Port.Size = New-Object System.Drawing.Size(40,20) 
    $Port.ReadOnly = $false
    $Port.Text = "5555"
    $Port.WordWrap = $false

    $Do_Connect = New-Object System.Windows.Forms.Button
    $Do_Connect.Location = New-Object System.Drawing.Point(180,100)
    $Do_Connect.Size = New-Object System.Drawing.Size(80,40)
    $Do_Connect.Text = "��ʼ����"
    $Do_Connect.add_click( {Do_Connect $IP.Text $Port.Text } )

    $ConnectForm.Controls.Add($IP)
    $ConnectForm.Controls.Add($Port)
    $ConnectForm.Controls.Add($Do_Connect)
    $ConnectForm.Controls.Add($IP_label)
    $ConnectForm.Controls.Add($Port_label)

    $ConnectForm.ShowDialog()
}

Function Do_Connect($ip, $port)
{
    $ws = New-Object -ComObject WScript.Shell
    $reg_ip = "^(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])$"
    $reg_port = "^\d{1,6}$"
    if ( $ip -ne "" )
    {
        if ( $ip -match $reg_ip )
        {
            if ( $port -match $reg_port )
            {
                $temp_result = adb connect ${ip}:${port}
                if ( $temp_result.Contains( "connected to" ) )
                {
                    $Info.Text = "�����ӳɹ���"
                    $wsr = $ws.popup("�����ӳɹ���",0,$title,0 + 64)
                    $ConnectForm.Close()
                }
                else
                {
                    $Info.Text = "����ʧ�ܣ�����IP��ַ���˿ںŻ�WIFI���á�"
                    $wsr = $ws.popup("����ʧ�ܣ�����IP��ַ���˿ںŻ�WIFI���á�",0,$title,0 + 64)
                }
            }
            else
            {
                $Info.Text = "����д��ȷ��ʽ�Ķ˿ںš�"
                
	            $wsr = $ws.popup("����д��ȷ��ʽ�Ķ˿ںš�",0,$title,0 + 64)
            }
        }
        else
        {
            $Info.Text = "����д��ȷ��ʽ��IP��ַ��"
            $ws = New-Object -ComObject WScript.Shell
	        $wsr = $ws.popup("����д��ȷ��ʽ��IP��ַ��",0,$title,0 + 64)
        }
    }
    else
    {
        $Info.Text = "IP��ַδ��д��"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("IP��ַδ��д��",0,$title,0 + 64)
    }
}

Function Disconnect
{
    try
    {
        adb disconnect
        $Info.Text = "�������ӵ�Զ���豸���ѶϿ���"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("�������ӵ�Զ���豸���ѶϿ���",0,$title,0 + 64)
    }
    catch [System.Exception]
    {
        $Info.Text = "�Ͽ��쳣��"
    }
}

Function Press_key($keycode)
{
    switch ( ( $device_count = List_devices ) )
	    {
            1 {$Warning_label.Text = "";adb shell input keyevent $keycode;break}
            0 {$Warning_label.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Warning_label.Text = "������̫��Android�豸����";break}
        }
}

Function Swipe_screen($start_x, $start_y, $end_x, $end_y)
{
    switch ( ( $device_count = List_devices ) )
	    {
            1 {$Warning_label.Text = "";adb shell input swipe $start_x $start_y $end_x $end_y;break}
            0 {$Warning_label.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Warning_label.Text = "������̫��Android�豸����";break}
        }
}

Function Screen_cap
{
    $ws = New-Object -ComObject WScript.Shell
    $imagename = "Screenshot_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".png"
    switch ( ( $device_count = List_devices ) )
	    {
            1 {
                try
                {
                    $Warning_label.Text = "";adb shell /system/bin/screencap -p /sdcard/$imagename;adb pull /sdcard/$imagename; $wsr = $ws.popup( "�����ɹ���ͼƬ������" + (Get-Location) + "\" + $imagename,0,$title,0 + 64); break
                }
                catch [System.Exception]
                {
                    $Warning_label.Text = "��ͼ����ʧ�ܣ�����Ŀ����̡�"
                }
               }
            0 {$Warning_label.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Warning_label.Text = "������̫��Android�豸����";break}
        }
}

Function SetBrightness($value)
{
    switch ( ( $device_count = List_devices ) )
	{
        1 {$Warning_label.Text = "";adb shell settings put system screen_brightness $value;break}
        0 {$Warning_label.Text = "û�ҵ��豸��";break}
        {$_ -ge 2} {$Warning_label.Text = "������̫��Android�豸����";break}
    }
}

Function Logcat( $param )
{
    $logcatname = "Logcat_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".txt"
    $ws = New-Object -ComObject WScript.Shell
    switch ( ( $device_count = List_devices ) )
        {
            1 {
                switch ( $param )
                    {
                        {$param -eq "snap"}{$Log.Text = (Show_in_line ($log_temp = adb logcat -d -v time));break}
                        {$param -eq "clear"}{adb logcat -c;$Log.Text = "�豸�ϵ�LogCat����ա�";$wsr = $ws.popup("�豸�ϵ�LogCat����ա�",0,$title,0 + 64);break}
                        {$param -eq "export"}{adb logcat -d -v time > $logcatname;$Log.Text = ("LogCat��־�ѵ�����`n��־�ѵ�����:`n" + (Get-Location) + "\" + $logcatname);$wsr = $ws.popup("LogCat��־�ѵ���",0,$title,0 + 64);break}
                        {$param -eq "trace"}{
                                                $trace_result = adb shell ls /data/anr

                                                if ($trace_result -eq $null)
                                                {
                                                    $Log.Text = "���ʱ��ܾ�����Ȩ�ޡ�";break
                                                }

                                                for ($i = 0;$i -lt $trace_result.Length;$i++)
                                                {
                                                    if ($trace_result[$i].toString() -eq "traces.txt")
                                                    {
                                                        adb pull /data/anr/traces.txt
                                                        $Log.Text = ("ANR trace�ļ��ѵ�����`n�ѵ�����:`n" + (Get-Location) + "\traces.txt");$wsr = $ws.popup("ANR trace�ļ��ѵ���",0,$title,0 + 64);break
                                                    }
                                                    elseif ($trace_result[$i].toString() -eq "traces.txt.bugreport")
                                                    {
                                                        adb pull /data/anr/traces.txt.bugreport
                                                        $Log.Text = ("trace�ļ������ڣ�����trace.txt.bugreport�ļ���`n�ѵ�����:`n" + (Get-Location) + "\traces.txt.bugreport");$wsr = $ws.popup("trace.txt.bugreport�ļ��ѵ���",0,$title,0 + 64);break
                                                    }
                                                    else
                                                    {
                                                        $Log.Text = "trace�ļ������ڣ��������Ƿ����ɻ��Ƿ�����ӦȨ�ޡ�";break
                                                    }
                                                };break
                                            }
                        default{$Log.Text = "?????"}
                    };break
              }
            0 {$Log.Text = "û�ҵ��豸��";break}
            {$_ -ge 2} {$Log.Text = "������̫���豸����";break}
        } 
    
}

Function FilterLog($keyword)
{
    switch (( $device_count = List_devices ))
    {
        1 {$Log.Text = (Show_in_line ($log_temp = adb logcat -d -v time | Where-Object {$_ -like "*" + $keyword + "*"}));break}
        0 {$Log.Text = "û�ҵ��豸��";break}
        {$_ -ge 2} {$Log.Text = "������̫���豸����";break}
    }
}

Function Show_in_line($target)
{
    $temp = $null
    for ($i = 0; $i -lt $target.length; $i++)
    {
        $temp = $temp + $target[$i] + "`n"
    }
    return $temp
}

Function GetMD5($filepath)
{
    return (((Get-FileHash $filepath -Algorithm MD5)|findstr "MD5").substring(15,48).Trim())
}

Function ShowOpenFileDialog
{
    $dialog = New-Object -TypeName Microsoft.Win32.OpenFileDialog
    $dialog.Title = 'ѡ��APK�ļ�'
    $dialog.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
    $dialog.Filter = 'APK files|*.apk|All|*.*'

    $dialog_shown = $dialog.ShowDialog()

    if ($dialog_shown -eq $true)
    {
        ShowAPKInfo $dialog.FileName
    }
}

Function ShowAPKInfo($filepath)
{
    $current = Get-Location
    $path = Get-Item -Path $env:ANDROID_SDK_HOME\build-tools
    $temp = ls $path
    $temp = $path.ToString() + "\" + $temp[$temp.Length-1].ToString() + "\"
    cd $temp
    cmd /c "aapt d badging $filepath > $env:TMP\temp.txt"
    cd $current

    $APK_path.Text = $filepath
    $APK_size.Text = ((Get-Item $filepath).Length).ToString() + " Byte"
    $APK_MD5.Text = GetMD5($filepath)

    $Package_name.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[1].Substring(5).Trim("'")
    $Version_code.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[2].Substring(12).Trim("'")
    $Version_name.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[3].Substring(12).Trim("'")
    $Min_sdk.Text = ((Get-Content $env:TMP\temp.txt)[2].split(" ")).Substring(11).Trim("'")
    $Target_sdk.Text = ((Get-Content $env:TMP\temp.txt)[3].split(" ")).Substring(17).Trim("'")
    #$APK_name.Text = ((Get-Content -Encoding UTF8 $env:TMP\temp.txt | findstr "application:").split(" "))[1].Substring(6).Trim("'")

    $APK_info_Button.Enabled = $true
}

Function ShowDetail
{
    notepad ($env:TMP + "\temp.txt")
}

Function About
{
    $AboutForm = New-Object System.Windows.Forms.Form
    $AboutForm.Text = $title
    $AboutForm.Size = New-Object System.Drawing.Size(300,200) 
    $AboutForm.StartPosition = "CenterScreen"
    $AboutForm.SizeGripStyle = "Hide"
    $AboutForm.MaximizeBox = $false
    $AboutForm.MinimizeBox = $false
    $AboutForm.AutoSize = $false
    $AboutForm.HelpButton = $false
    $AboutForm.ShowInTaskbar = $false
    $AboutForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

    $Author_label = New-Object System.Windows.Forms.Label
    $Author_label.Location = New-Object System.Drawing.Point(20,80)
    $Author_label.Size = New-Object System.Drawing.Size(200,20)
    $Author_label.Text = "���ߣ�������"

    $Version_label = New-Object System.Windows.Forms.Label
    $Version_label.Location = New-Object System.Drawing.Point(20,50)
    $Version_label.Size = New-Object System.Drawing.Size(200,20)
    $Version_label.Text = "�汾�� " + $Global:version

    $Name_label = New-Object System.Windows.Forms.Label
    $Name_label.Location = New-Object System.Drawing.Point(20,20)
    $Name_label.Size = New-Object System.Drawing.Size(200,20)
    $Name_label.Text = "PowerShell Tool Box"

    $OK_button = New-Object System.Windows.Forms.Button
    $OK_button.Text = "ţB!!"
    $OK_button.Location = New-Object System.Drawing.Point(200,60)
    $OK_button.Size = New-Object System.Drawing.Size(60,40)
    $OK_button.add_Click({$AboutForm.Close()})

    $HomePage_button = New-Object System.Windows.Forms.Button
    $HomePage_button.Text = "������Ŀ��ҳ"
    $HomePage_button.Location = New-Object System.Drawing.Point(20,120)
    $HomePage_button.Size = New-Object System.Drawing.Size(100,30)
    $HomePage_button.add_Click({Start-Process -FilePath https://github.com/titan1983/PowerShellToolBox})

    $Mail_button = New-Object System.Windows.Forms.Button
    $Mail_button.Text = "�����ʼ�������"
    $Mail_button.Location = New-Object System.Drawing.Point(160,120)
    $Mail_button.Size = New-Object System.Drawing.Size(100,30)
    $Mail_button.add_Click({Start-Process -FilePath mailto:titan_1983@163.com})

    $AboutForm.Controls.Add($OK_button)
    $AboutForm.Controls.Add($Author_label)
    $AboutForm.Controls.Add($Version_label)
    $AboutForm.Controls.Add($Name_label)
    $AboutForm.Controls.Add($HomePage_button)
    $AboutForm.Controls.Add($Mail_button)

    $AboutForm.ShowDialog()
}

Function StartUp
{
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $title
    $MainForm.Size = New-Object System.Drawing.Size(720,520) 
    $MainForm.StartPosition = "CenterScreen"
    $MainForm.SizeGripStyle = "Hide"
    $MainForm.MaximizeBox = $false
    $MainForm.AutoSize = $false
    $MainForm.HelpButton = $True
    $MainForm.ShowInTaskbar = $True
    $MainForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

    #���Ǹ����ɼ��Ŀؼ�����Tabҳ�ؼ�����������������ʹ����Сд��ͷ��
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(0, 10);
    $tabControl.SelectedIndex = 0;
    $tabControl.Size = New-Object System.Drawing.Size(700, 400);
    $tabControl.TabIndex = 0

    $Tab_power = New-Object System.Windows.Forms.TabPage
    $Tab_adb_tools = New-Object System.Windows.Forms.TabPage
    $Tab_logcat = New-Object System.Windows.Forms.TabPage
    $Tab_option = New-Object System.Windows.Forms.TabPage
    $Tab_apk_info = New-Object System.Windows.Forms.TabPage
    $Tab_CPU_MEM = New-Object System.Windows.Forms.TabPage

    $Tab_power.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_power.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_power.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_power.TabIndex = 0;
    $Tab_power.Text = "�����������";
    $Tab_power.UseVisualStyleBackColor = "true";

    $Tab_adb_tools.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_adb_tools.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_adb_tools.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_adb_tools.TabIndex = 0;
    $Tab_adb_tools.Text = "ADB���ù���";
    $Tab_adb_tools.UseVisualStyleBackColor = "true";

    $Tab_logcat.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_logcat.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_logcat.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_logcat.TabIndex = 0;
    $Tab_logcat.Text = "Logcat����";
    $Tab_logcat.UseVisualStyleBackColor = "true";

    $Tab_option.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_option.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_option.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_option.TabIndex = 0;
    $Tab_option.Text = "�ֻ�ģ�����";
    $Tab_option.UseVisualStyleBackColor = "true";

    $Tab_apk_info.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_apk_info.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_apk_info.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_apk_info.TabIndex = 0;
    $Tab_apk_info.Text = "APK��Ϣ��ѯ";
    $Tab_apk_info.UseVisualStyleBackColor = "true";
    $Tab_apk_info.AllowDrop = $True

    #����Ϊtab_powerҳ��Ԫ��
    $Init_Button = New-Object System.Windows.Forms.Button
    $Init_Button.Location = New-Object System.Drawing.Point(560,40)
    $Init_Button.Size = New-Object System.Drawing.Size(120,40)
    $Init_Button.Text = "���������ʼ��"
    $Init_Button.add_click( {Init_power} )

    $List_Button = New-Object System.Windows.Forms.Button
    $List_Button.Location = New-Object System.Drawing.Point(560,100)
    $List_Button.Size = New-Object System.Drawing.Size(120,40)
    $List_Button.Text = "������Android�豸"
    $List_Button.add_click( {List_devices} )

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(560,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "����Bugreport��־"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Run_batt_Button = New-Object System.Windows.Forms.Button
    $Run_batt_Button.Location = New-Object System.Drawing.Point(560,220)
    $Run_batt_Button.Size = New-Object System.Drawing.Size(120,40)
    $Run_batt_Button.Text = "����`nBattery-Historian"
    $Run_batt_Button.add_click( {Run_battery_historian} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(500,340) 
    $Console.ReadOnly = $True
    $Console.Text = "ִ�н����ʾ������"
    $Console.WordWrap = $True
    $Console.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Console.BackColor = ([System.Drawing.Color]::Black)
    $Console.Font = New-Object System.Drawing.Font("Microsoft YaHei",16,[System.Drawing.FontStyle]::Regular)

    #����Ϊtab_adb_toolsҳ��Ԫ��
    $Show_devices_info_Button = New-Object System.Windows.Forms.Button
    $Show_devices_info_Button.Location = New-Object System.Drawing.Point(560,40)
    $Show_devices_info_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_devices_info_Button.Text = "��ʾ�豸��Ϣ"
    $Show_devices_info_Button.add_click( {Show_devices_info} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(560,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "����Android�豸"
    $Reboot_Button.add_click( {Reboot} )

    $Connect_Button = New-Object System.Windows.Forms.Button
    $Connect_Button.Location = New-Object System.Drawing.Point(560,160)
    $Connect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Connect_Button.Text = "Զ������`nAndroid�豸"
    $Connect_Button.add_click( {Connect_devices} )

    $Disconnect_Button = New-Object System.Windows.Forms.Button
    $Disconnect_Button.Location = New-Object System.Drawing.Point(560,220)
    $Disconnect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Disconnect_Button.Text = "�Ͽ�����Զ���豸"
    $Disconnect_Button.add_click( {Disconnect} )

    $Info = New-Object System.Windows.Forms.RichTextBox
    $Info.Location = New-Object System.Drawing.Point(20,40) 
    $Info.Size = New-Object System.Drawing.Size(500,340) 
    $Info.ReadOnly = $True
    $Info.Text = "���뿴��ɶ��"
    $Info.WordWrap = $True
    $Info.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Info.BackColor = ([System.Drawing.Color]::Black)
    $Info.Font = New-Object System.Drawing.Font("Microsoft YaHei",16,[System.Drawing.FontStyle]::Regular)

    #����Ϊtab_logcatҳ��Ԫ��
    $Log = New-Object System.Windows.Forms.RichTextBox
    $Log.Location = New-Object System.Drawing.Point(20,60) 
    $Log.Size = New-Object System.Drawing.Size(650,280) 
    $Log.ReadOnly = $True
    $Log.Text = "==== LogCat���� ===="
    $Log.WordWrap = $True
    $Log.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Log.BackColor = ([System.Drawing.Color]::Black)

    $Log_snap_Button = New-Object System.Windows.Forms.Button
    $Log_snap_Button.Location = New-Object System.Drawing.Point(20,10)
    $Log_snap_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_snap_Button.Text = "ץȡLOGCAT����"
    $Log_snap_Button.add_click( {Logcat "snap"} )

    $Log_clear_Button = New-Object System.Windows.Forms.Button
    $Log_clear_Button.Location = New-Object System.Drawing.Point(160,10)
    $Log_clear_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_clear_Button.Text = "���LOGCAT��־"
    $Log_clear_Button.add_click( {Logcat "clear"} )

    $Log_export_Button = New-Object System.Windows.Forms.Button
    $Log_export_Button.Location = New-Object System.Drawing.Point(300,10)
    $Log_export_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_export_Button.Text = "����LOGCAT��־"
    $Log_export_Button.add_click( {Logcat "export"} )

    $Trace_export_Button = New-Object System.Windows.Forms.Button
    $Trace_export_Button.Location = New-Object System.Drawing.Point(440,10)
    $Trace_export_Button.Size = New-Object System.Drawing.Size(100,40)
    $Trace_export_Button.Text = "����trace�ļ�"
    $Trace_export_Button.add_click( {Logcat "trace"} )

    $Log_filter_Button = New-Object System.Windows.Forms.Button
    $Log_filter_Button.Location = New-Object System.Drawing.Point(20,340)
    $Log_filter_Button.Size = New-Object System.Drawing.Size(60,30)
    $Log_filter_Button.Text = "����"
    $Log_filter_Button.add_click( {FilterLog $Filter_box.Text.toString()} )

    $Filter_box = New-Object System.Windows.Forms.RichTextBox
    $Filter_box.Location = New-Object System.Drawing.Point(100,340) 
    $Filter_box.Size = New-Object System.Drawing.Size(570,30) 
    $Filter_box.ReadOnly = $false
    $Filter_box.Text = ""
    $Filter_box.WordWrap = $false
    $Filter_box.ForeColor = ([System.Drawing.Color]::Orange)
    $Filter_box.BackColor = ([System.Drawing.Color]::Blue)
    $Filter_box.Font = New-Object System.Drawing.Font("Tahoma",12,[System.Drawing.FontStyle]::Bold)

    #����Ϊtab_optionҳ��Ԫ��
    $Home_Button = New-Object System.Windows.Forms.Button
    $Home_Button.Location = New-Object System.Drawing.Point(200,300)
    $Home_Button.Size = New-Object System.Drawing.Size(100,40)
    $Home_Button.Text = "Home"
    $Home_Button.add_click( {Press_key 3} )

    $Back_Button = New-Object System.Windows.Forms.Button
    $Back_Button.Location = New-Object System.Drawing.Point(80,300)
    $Back_Button.Size = New-Object System.Drawing.Size(100,40)
    $Back_Button.Text = "Back"
    $Back_Button.add_click( {Press_key 4} )

    $Menu_Button = New-Object System.Windows.Forms.Button
    $Menu_Button.Location = New-Object System.Drawing.Point(320,300)
    $Menu_Button.Size = New-Object System.Drawing.Size(100,40)
    $Menu_Button.Text = "Menu"
    $Menu_Button.add_click( {Press_key 82} )

    $Power_Button = New-Object System.Windows.Forms.Button
    $Power_Button.Location = New-Object System.Drawing.Point(500,60)
    $Power_Button.Size = New-Object System.Drawing.Size(100,40)
    $Power_Button.Text = "Power"
    $Power_Button.add_click( {Press_key 26} )

    $Vol_up_Button = New-Object System.Windows.Forms.Button
    $Vol_up_Button.Location = New-Object System.Drawing.Point(500,120)
    $Vol_up_Button.Size = New-Object System.Drawing.Size(100,40)
    $Vol_up_Button.Text = "Volumn +"
    $Vol_up_Button.add_click( {Press_key 24} )

    $Vol_down_Button = New-Object System.Windows.Forms.Button
    $Vol_down_Button.Location = New-Object System.Drawing.Point(500,180)
    $Vol_down_Button.Size = New-Object System.Drawing.Size(100,40)
    $Vol_down_Button.Text = "Volumn -"
    $Vol_down_Button.add_click( {Press_key 25} )

    $Swipe_up_Button = New-Object System.Windows.Forms.Button
    $Swipe_up_Button.Location = New-Object System.Drawing.Point(200,40)
    $Swipe_up_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_up_Button.Text = "���ϻ���"
    $Swipe_up_Button.add_click( {Swipe_screen 500 800 500 200} )

    $Swipe_down_Button = New-Object System.Windows.Forms.Button
    $Swipe_down_Button.Location = New-Object System.Drawing.Point(200,200)
    $Swipe_down_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_down_Button.Text = "���»���"
    $Swipe_down_Button.add_click( {Swipe_screen 500 300 500 800} )

    $Swipe_left_Button = New-Object System.Windows.Forms.Button
    $Swipe_left_Button.Location = New-Object System.Drawing.Point(60,120)
    $Swipe_left_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_left_Button.Text = "���󻬶�"
    $Swipe_left_Button.add_click( {Swipe_screen 500 500 100 500} )

    $Swipe_right_Button = New-Object System.Windows.Forms.Button
    $Swipe_right_Button.Location = New-Object System.Drawing.Point(340,120)
    $Swipe_right_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_right_Button.Text = "���һ���"
    $Swipe_right_Button.add_click( {Swipe_screen 100 500 500 500} )

    $Screen_cap_Button = New-Object System.Windows.Forms.Button
    $Screen_cap_Button.Location = New-Object System.Drawing.Point(200,120)
    $Screen_cap_Button.Size = New-Object System.Drawing.Size(100,40)
    $Screen_cap_Button.Text = "��Ļ��ͼ"
    $Screen_cap_Button.add_click( {Screen_cap} )

    $Brightness_Max_Button = New-Object System.Windows.Forms.Button
    $Brightness_Max_Button.Location = New-Object System.Drawing.Point(520,260)
    $Brightness_Max_Button.Size = New-Object System.Drawing.Size(90,30)
    $Brightness_Max_Button.Text = "��Ļ��������"
    $Brightness_Max_Button.add_click( {SetBrightness 255} )


    $Brightness_Min_Button = New-Object System.Windows.Forms.Button
    $Brightness_Min_Button.Location = New-Object System.Drawing.Point(520,300)
    $Brightness_Min_Button.Size = New-Object System.Drawing.Size(90,30)
    $Brightness_Min_Button.Text = "��Ļ�����"
    $Brightness_Min_Button.add_click( {SetBrightness 1} )


    $Warning_label = New-Object System.Windows.Forms.Label
    $Warning_label.Location = New-Object System.Drawing.Point(20,10)
    $Warning_label.Size = New-Object System.Drawing.Size(300,40)
    $Warning_label.Text = ""
    $Warning_label.ForeColor = "Red"
    $Warning_label.Font = New-Object System.Drawing.Font("Tahoma",12,[System.Drawing.FontStyle]::Bold)

    #����Ϊtab_apk_infoҳ��Ԫ��
    $OpenFile_button = New-Object System.Windows.Forms.Button
    $OpenFile_button.Location = New-Object System.Drawing.Point(580,300)
    $OpenFile_button.Size = New-Object System.Drawing.Size(90,40)
    $OpenFile_button.Text = "��APK�ļ�"
    $OpenFile_button.add_click( {ShowOpenFileDialog} )

    $APK_name = New-Object System.Windows.Forms.RichTextBox
    $APK_name.Location = New-Object System.Drawing.Point(120,20) 
    $APK_name.Size = New-Object System.Drawing.Size(300,25) 
    $APK_name.ReadOnly = $True
    $APK_name.Text = ""
    $APK_name.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $APK_name.ForeColor = "#370fa5"

    $APK_name_label = New-Object System.Windows.Forms.Label
    $APK_name_label.Location = New-Object System.Drawing.Point(20,20)
    $APK_name_label.Size = New-Object System.Drawing.Size(100,25)
    $APK_name_label.Text = "Ӧ�����ƣ�"

    $APK_path = New-Object System.Windows.Forms.RichTextBox
    $APK_path.Location = New-Object System.Drawing.Point(120,280) 
    $APK_path.Size = New-Object System.Drawing.Size(400,50) 
    $APK_path.ReadOnly = $True
    $APK_path.Text = ""
    $APK_path.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $APK_path.ForeColor = "#370fa5"

    $APK_path_label = New-Object System.Windows.Forms.Label
    $APK_path_label.Location = New-Object System.Drawing.Point(20,280)
    $APK_path_label.Size = New-Object System.Drawing.Size(100,25)
    $APK_path_label.Text = "APK·����"

    $APK_size = New-Object System.Windows.Forms.RichTextBox
    $APK_size.Location = New-Object System.Drawing.Point(120,340) 
    $APK_size.Size = New-Object System.Drawing.Size(100,25) 
    $APK_size.ReadOnly = $True
    $APK_size.Text = ""
    $APK_size.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $APK_size.ForeColor = "#370fa5"

    $APK_size_label = New-Object System.Windows.Forms.Label
    $APK_size_label.Location = New-Object System.Drawing.Point(20,340)
    $APK_size_label.Size = New-Object System.Drawing.Size(100,25)
    $APK_size_label.Text = "APK�ļ���С��"

    $Package_name = New-Object System.Windows.Forms.RichTextBox
    $Package_name.Location = New-Object System.Drawing.Point(120,60) 
    $Package_name.Size = New-Object System.Drawing.Size(300,25) 
    $Package_name.ReadOnly = $True
    $Package_name.Text = ""
    $Package_name.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Package_name.ForeColor = "#370fa5"

    $Package_name_label = New-Object System.Windows.Forms.Label
    $Package_name_label.Location = New-Object System.Drawing.Point(20,60)
    $Package_name_label.Size = New-Object System.Drawing.Size(100,25)
    $Package_name_label.Text = "APK������"

    $Version_name = New-Object System.Windows.Forms.RichTextBox
    $Version_name.Location = New-Object System.Drawing.Point(120,100) 
    $Version_name.Size = New-Object System.Drawing.Size(100,25) 
    $Version_name.ReadOnly = $True
    $Version_name.Text = ""
    $Version_name.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Version_name.ForeColor = "#370fa5"

    $Version_name_label = New-Object System.Windows.Forms.Label
    $Version_name_label.Location = New-Object System.Drawing.Point(20,100)
    $Version_name_label.Size = New-Object System.Drawing.Size(100,25)
    $Version_name_label.Text = "Version Name��"

    $Version_code = New-Object System.Windows.Forms.RichTextBox
    $Version_code.Location = New-Object System.Drawing.Point(120,140) 
    $Version_code.Size = New-Object System.Drawing.Size(100,25) 
    $Version_code.ReadOnly = $True
    $Version_code.Text = ""
    $Version_code.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Version_code.ForeColor = "#370fa5"

    $Version_code_label = New-Object System.Windows.Forms.Label
    $Version_code_label.Location = New-Object System.Drawing.Point(20,140)
    $Version_code_label.Size = New-Object System.Drawing.Size(100,25)
    $Version_code_label.Text = "Version Code��"

    $Target_sdk = New-Object System.Windows.Forms.RichTextBox
    $Target_sdk.Location = New-Object System.Drawing.Point(120,180) 
    $Target_sdk.Size = New-Object System.Drawing.Size(100,25) 
    $Target_sdk.ReadOnly = $True
    $Target_sdk.Text = ""
    $Target_sdk.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Target_sdk.ForeColor = "#370fa5"

    $Target_sdk_label = New-Object System.Windows.Forms.Label
    $Target_sdk_label.Location = New-Object System.Drawing.Point(20,180)
    $Target_sdk_label.Size = New-Object System.Drawing.Size(100,25)
    $Target_sdk_label.Text = "����ϵͳ�ȼ���"

    $Min_sdk = New-Object System.Windows.Forms.RichTextBox
    $Min_sdk.Location = New-Object System.Drawing.Point(120,220) 
    $Min_sdk.Size = New-Object System.Drawing.Size(100,25) 
    $Min_sdk.ReadOnly = $True
    $Min_sdk.Text = ""
    $Min_sdk.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Min_sdk.ForeColor = "#370fa5"

    $Min_sdk_label = New-Object System.Windows.Forms.Label
    $Min_sdk_label.Location = New-Object System.Drawing.Point(20,220)
    $Min_sdk_label.Size = New-Object System.Drawing.Size(100,25)
    $Min_sdk_label.Text = "���ϵͳ�ȼ���"

    $APK_MD5 = New-Object System.Windows.Forms.RichTextBox
    $APK_MD5.Location = New-Object System.Drawing.Point(120,20) 
    $APK_MD5.Size = New-Object System.Drawing.Size(200,25) 
    $APK_MD5.ReadOnly = $True
    $APK_MD5.Text = ""
    $APK_MD5.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $APK_MD5.ForeColor = "#370fa5"

    $APK_MD5_label = New-Object System.Windows.Forms.Label
    $APK_MD5_label.Location = New-Object System.Drawing.Point(22,20)
    $APK_MD5_label.Size = New-Object System.Drawing.Size(100,25)
    $APK_MD5_label.Text = "MD5��"

    $APK_info_Button = New-Object System.Windows.Forms.Button
    $APK_info_Button.Location = New-Object System.Drawing.Point(580,220)
    $APK_info_Button.Size = New-Object System.Drawing.Size(90,40)
    $APK_info_Button.Text = "�鿴��ϸ��Ϣ"
    $APK_info_Button.add_click( {ShowDetail} )
    $APK_info_Button.Enabled = $false

    #����Ϊ��������ʾԪ��
    $Time_label = New-Object System.Windows.Forms.Label
    $Time_label.Location = New-Object System.Drawing.Point(20,450)
    $Time_label.Size = New-Object System.Drawing.Size(400,20)
    $Time_label.Text = "���������ڣ�" + (Get-Date -Format "yyyy��M��dd�� dddd HH:mm:ss")
    $Time_label.Font = New-Object System.Drawing.Font("Microsoft YaHei",10,[System.Drawing.FontStyle]::Regular)

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(580,420)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "�˳�"
    $Exit_Button.add_click( {$MainForm.Close()} )

    $About_Button = New-Object System.Windows.Forms.Button
    $About_Button.Location = New-Object System.Drawing.Point(500,420)
    $About_Button.Size = New-Object System.Drawing.Size(60,40)
    $About_Button.Text = "����"
    $About_Button.add_click( {About} )

    $MainForm.Controls.Add($Exit_Button)
    $MainForm.Controls.Add($About_Button)
    $MainForm.Controls.Add($Time_label)
    $MainForm.Controls.Add($tabControl)
    
    $tabControl.Controls.Add($Tab_power)
    $tabControl.Controls.Add($Tab_adb_tools)
    $tabControl.Controls.Add($Tab_logcat)
    $tabControl.Controls.Add($Tab_option)
    $tabControl.Controls.Add($Tab_apk_info)
    #$tabControl.Controls.Add($Tab_CPU_MEM)

    $Tab_power.Controls.Add($Export_bugreport_Button)
    $Tab_power.Controls.Add($Init_Button)
    $Tab_power.Controls.Add($Console)
    $Tab_power.Controls.Add($List_Button)
    $Tab_power.Controls.Add($Run_batt_Button)

    $Tab_adb_tools.Controls.Add($Show_devices_info_Button)
    $Tab_adb_tools.Controls.Add($Info)
    $Tab_adb_tools.Controls.Add($Reboot_Button)
    $Tab_adb_tools.Controls.Add($Connect_Button)
    $Tab_adb_tools.Controls.Add($Disconnect_Button)

    $Tab_logcat.Controls.Add($Log_filter_Button)
    $Tab_logcat.Controls.Add($Log)
    $Tab_logcat.Controls.Add($Log_snap_Button)
    $Tab_logcat.Controls.Add($Log_clear_Button)
    $Tab_logcat.Controls.Add($Log_export_Button)
    $Tab_logcat.Controls.Add($Trace_export_Button)
    $Tab_logcat.Controls.Add($Filter_box)

    $Tab_option.Controls.Add($Home_Button)
    $Tab_option.Controls.Add($Back_Button)
    $Tab_option.Controls.Add($Menu_Button)
    $Tab_option.Controls.Add($Power_Button)
    $Tab_option.Controls.Add($Vol_up_Button)
    $Tab_option.Controls.Add($Vol_down_Button)
    $Tab_option.Controls.Add($Swipe_up_Button)
    $Tab_option.Controls.Add($Swipe_down_Button)
    $Tab_option.Controls.Add($Swipe_left_Button)
    $Tab_option.Controls.Add($Swipe_right_Button)
    $Tab_option.Controls.Add($Warning_label)
    $Tab_option.Controls.Add($Screen_cap_Button)
    $Tab_option.Controls.Add($Brightness_Max_Button)
    $Tab_option.Controls.Add($Brightness_Min_Button)

    $Tab_apk_info.Controls.Add($OpenFile_button)
    $Tab_apk_info.Controls.Add($APK_size)
    $Tab_apk_info.Controls.Add($APK_size_label)
    $Tab_apk_info.Controls.Add($APK_path)
    $Tab_apk_info.Controls.Add($APK_path_label)
    $Tab_apk_info.Controls.Add($Package_name)
    $Tab_apk_info.Controls.Add($Package_name_label)
    $Tab_apk_info.Controls.Add($Version_name)
    $Tab_apk_info.Controls.Add($Version_name_label)
    $Tab_apk_info.Controls.Add($Version_code)
    $Tab_apk_info.Controls.Add($Version_code_label)
    $Tab_apk_info.Controls.Add($Target_sdk)
    $Tab_apk_info.Controls.Add($Target_sdk_label)
    $Tab_apk_info.Controls.Add($Min_sdk)
    $Tab_apk_info.Controls.Add($Min_sdk_label)
    $Tab_apk_info.Controls.Add($APK_info_button)
    $Tab_apk_info.Controls.Add($APK_MD5)
    $Tab_apk_info.Controls.Add($APK_MD5_label)

    $MainForm.Add_Shown({$MainForm.Activate()})
    $MainForm.ShowDialog()
}

StartUp