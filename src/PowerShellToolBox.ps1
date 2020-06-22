#Created by Tian Xiaodong
#请将脚本文件保存为ANSI编码格式，否则无法正常输出中文字符。

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

#Global Define
$Global:title = "PowerShell 懒人工具"
$Global:version = "1.0.12"

Function Init_power
{
    $warning = "即将开始功耗评测初始化，点击OK键继续，点击Cancel键退出。`nInitial is coming, press `"OK`" to continue, or press `"Cancel`" to abort."
    $done = "初始化完成，请尽快完成评测。`nDone, please do the evaluation ASAP."

    $ws = New-Object -ComObject WScript.Shell
    $wsr = $ws.popup($warning,0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( List_devices )
	    {
            1 {
                $list_devices = adb devices

                switch ( $list_devices )
                {
                    {($list_devices[1].Contains( ":" ))}{$Console.Text = "远程设备，不予以初始化。";break}
                    {($list_devices[1].Contains("unauthorized"))}{$Console.Text = "设备未授权。";break}
                default
                {
                    $init_1 = adb shell dumpsys batterystats --reset
                    $init_2 = adb shell dumpsys batterystats --enable full-wake-history
        
                    if ( ( $null -ne $init_1 ) -or ( $null -ne $init_2 ) )
                    {
                        $Console.Text = [string]$init_1 + "`n" + [string]$init_2
                        $ws.popup($done,0,$title,0 + 64)
                    }
                    else
                    {
                        $Console.Text = "初始化失败，请检查手机连接或ADB环境。"
                    }
                    ;break
                }
               }
              ;break}
            0 {$Console.Text = "没找到设备。";break}
            {$_ -ge 2} {$Console.Text = "连接了太多Android设备啦！";break}
        }
    }
    else
    {
        $Console.Text = "初始化已取消。放心，我们啥都没干。"
    }
    return
}

Function List_devices
#这个函数很重要，多处判断均依赖该函数的运行结果。
#返回已连接Android设备的数量，类型为整形。
{
    $global:list_devices = adb devices

    if ( $null -ne $list_devices )
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
        $Console.Text = $temp + "`n当前已连接 “ + ($list_devices.Count-2) + ” 台Android设备。" + "`n其中包含 “ + “$wireless_count” + ” 台无线连接设备。"
        return [int]( $list_devices.Count - 2 )
    }
    else
    {
        $Console.Text = "执行失败，请检查ADB环境。"
    }
}

Function Export_bugreport
#如果只连接了一台远程设备，则不导出。因为远程设备导出的Bugreport无效。
{
    $temp_dir = Get-Location
    switch ( List_devices )
    {
        1 {
            try
            {
                $list_devices = adb devices

                switch ( ( $list_devices ) )
                {
                    {$list_devices[1].Contains( ":" )}{$Console.Text = "远程设备，不予以导出日志。";break}
                    {$list_devices[1].Contains( "unauthorized" )}{$Console.Text = "设备未授权。";break}
                    default
                    {
                        $Console.Text = "正在导出，此过程会耗时数分钟，请耐心等待。`n导出完成前本工具不可点击。"
                        if ( Test-Path bugreport_log )
                        {
                            Set-Location bugreport_log
                        }
                        else
                        {
                            mkdir bugreport_log
                            Set-Location bugreport_log
                        }

                        if ( ( adb shell getprop ro.build.version.sdk ) -ge 24 )
                        {
                            adb bugreport
                        }
                        else
                        {
                            $filename = "Bugreport_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".txt"
                            adb bugreport > $filename
                        }

                        $Console.Text = “导出完成！`n” + "Bugreport日志文件已存放于：`n" + ( Get-Location )
                        Set-Location $temp_dir
                        $ws = New-Object -ComObject WScript.Shell
                        $ws.popup(“导出完成！”,0,$title,0 + 64)
                        ;break
                    }
                }
            }
            catch [System.Exception]
            {
                $Console.Text = "执行失败，请检查手机连接或ADB环境。"
            };break
          }
        0 {$Console.Text = "没找到设备。";break}
        {$_ -ge 2 } {$Console.Text = "连接了太多设备啦！`n导出时电脑上只能连接一台Android设备。";break}
    }
}

Function Run_battery_historian
{
    $temp_dir = Get-Location

    if ( get-process | where-object {$_.Name -eq "battery-historian"} )
    {
	    write-host "Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/" -ForegroundColor Red
        $Console.Text = "Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/"
        $ws = New-Object -ComObject WScript.Shell
	    $ws.popup("Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/",0,"PowerShell 懒人工具系列",0 + 64)
        Start-Process -FilePath http://localhost:9999/
    }

    else
    {
        $Console.Text = "Battery Historian 正在运行。`n请访问 http://localhost:9999/"
	    $path = Get-Item -Path $env:GOPATH\src\github.com\google\battery-historian
	    
        if ( $null -ne $path )
        {
            Set-Location $path
            Start-Process powershell.exe -ArgumentList "write-host Battery Historian 正在运行，请不要关闭此窗口。 -ForegroundColor Yellow `ngo run cmd/battery-historian/battery-historian.go" -WindowStyle Minimized
        }
        else
        {
            $Console.Text = "工具都没装你运行个毛线！"
        }
        Set-Location $temp_dir
    }
}

Function Show_devices_info
{
    switch ( List_devices )
    {
        1 {
            if ( $list_devices[1].Contains("unauthorized") )
            {    
                $Info.Text = "设备尚未授权。"
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
                    $Device_date = adb shell date
                    $Info.Text = "Android版本: " + (isNull $Get_android_ver) + "`nAndroid API: " + (isNull $Get_android_API) + "`n屏幕分辨率: " + (isNull $Get_screen_res) + "`n屏幕DPI: " + (isNull $Get_screen_dpi) + "`n制造商: " + (isNull $Get_manuf) + "`n型号: " + (isNull $Get_model) + "`nCPU: " + (isNull $Get_CPU).Substring(11) + "`nCPU核心数: " + $Get_cores.length + "`n物理内存: " + (isNull $Get_Mem).Substring(11).trim() + "`n内部存储空间: " + $total_storage + "`n已用空间: " + $used_storage + "`n剩余空间: " + $free_storage + "`n" + $WIFI_stat[0] + "`n设备时间: " + $Device_date
                }
                catch [System.Exception]
                {
                    $Info.Text = "执行失败，请检查手机连接或ADB环境。"
                }
            }
            ;break
          }
        0 {$Info.Text = "没找到设备。";break}
        {$_ -ge 2 } {$Info.Text = "连了这么多台设备，我哪知道要查哪个。";break}
    }
}

Function Get_storage
{
    $Get_storage = adb shell df /data/

    if ( ( adb shell getprop ro.build.version.sdk ) -ge 24 )
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
    $wsr = $ws.popup("即将重启设备，确定要继续？",0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( List_devices )
        {
            1 {
                $Info.Text = "正在重启，请稍候。"
                adb reboot
                $Info.Text = "已重启，请检查设备。";break
              }
            0 {$Info.Text = "没找到设备。";break}
            {$_ -ge 2} {$Info.Text = "连接了太多设备啦！没法重启。";break}
        }       
    }
    else
    {
        $Info.Text = "好好好，不重启了。"
    }
}

Function isNull($target)
{
    if ( $null -ne $target )
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
    $IP_label.Text = "请输入正确格式的IP地址："

    $Port_label = New-Object System.Windows.Forms.Label
    $Port_label.Location = New-Object System.Drawing.Point(10,70)
    $Port_label.Size = New-Object System.Drawing.Size(300,20)
    $Port_label.Text = "请输入正确格式的端口号（可选）："

    $Port = New-Object System.Windows.Forms.TextBox
    $Port.Location = New-Object System.Drawing.Point(15,90) 
    $Port.Size = New-Object System.Drawing.Size(40,20) 
    $Port.ReadOnly = $false
    $Port.Text = "5555"
    $Port.WordWrap = $false

    $Do_Connect = New-Object System.Windows.Forms.Button
    $Do_Connect.Location = New-Object System.Drawing.Point(180,100)
    $Do_Connect.Size = New-Object System.Drawing.Size(80,40)
    $Do_Connect.Text = "开始连接"
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
                    $Info.Text = "已连接成功。"
                    $ws.popup("已连接成功。",0,$title,0 + 64)
                    $ConnectForm.Close()
                }
                else
                {
                    $Info.Text = "连接失败，请检查IP地址、端口号或WIFI设置。"
                    $ws.popup("连接失败，请检查IP地址、端口号或WIFI设置。",0,$title,0 + 64)
                }
            }
            else
            {
                $Info.Text = "请填写正确格式的端口号。"
                
	            $ws.popup("请填写正确格式的端口号。",0,$title,0 + 64)
            }
        }
        else
        {
            $Info.Text = "请填写正确格式的IP地址。"
            $ws = New-Object -ComObject WScript.Shell
	        $ws.popup("请填写正确格式的IP地址。",0,$title,0 + 64)
        }
    }
    else
    {
        $Info.Text = "IP地址未填写。"
        $ws = New-Object -ComObject WScript.Shell
	    $ws.popup("IP地址未填写。",0,$title,0 + 64)
    }
}

Function Disconnect
{
    try
    {
        adb disconnect
        $Info.Text = "所有连接的远程设备均已断开。"
        $ws = New-Object -ComObject WScript.Shell
	    $ws.popup("所有连接的远程设备均已断开。",0,$title,0 + 64)
    }
    catch [System.Exception]
    {
        $Info.Text = "断开异常。"
    }
}

Function ListPackage
{
    switch ( List_devices )
	{
        1 {$Info.Text = adb shell pm list package;break}
        0 {$Info.Text = "没找到设备。";break}
        {$_ -ge 2} {$Info.Text = "连接了太多Android设备啦！";break}
    }
}

Function Press_key($keycode)
{
    switch ( List_devices )
	    {
            1 {$Warning_label.Text = "";adb shell input keyevent $keycode;break}
            0 {$Warning_label.Text = "没找到设备。";break}
            {$_ -ge 2} {$Warning_label.Text = "连接了太多Android设备啦！";break}
        }
}

Function Swipe_screen($start_x, $start_y, $end_x, $end_y)
{
    switch ( List_devices )
	    {
            1 {$Warning_label.Text = "";adb shell input swipe $start_x $start_y $end_x $end_y;break}
            0 {$Warning_label.Text = "没找到设备。";break}
            {$_ -ge 2} {$Warning_label.Text = "连接了太多Android设备啦！";break}
        }
}

Function Screen_cap
{
    $ws = New-Object -ComObject WScript.Shell
    $imagename = "Screenshot_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".png"
    switch ( List_devices )
	    {
            1 {
                try
                {
                    $Warning_label.Text = "";adb shell /system/bin/screencap -p /sdcard/$imagename;adb pull /sdcard/$imagename; $ws.popup( "截屏成功！图片保存在" + (Get-Location) + "\" + $imagename,0,$title,0 + 64); break
                }
                catch [System.Exception]
                {
                    $Warning_label.Text = "截图保存失败，请检查目标磁盘。"
                }
               }
            0 {$Warning_label.Text = "没找到设备。";break}
            {$_ -ge 2} {$Warning_label.Text = "连接了太多Android设备啦！";break}
        }
}

Function SetBrightness($value)
{
    switch ( List_devices )
	{
        1 {$Warning_label.Text = "";adb shell settings put system screen_brightness $value;break}
        0 {$Warning_label.Text = "没找到设备。";break}
        {$_ -ge 2} {$Warning_label.Text = "连接了太多Android设备啦！";break}
    }
}

Function Logcat( $param )
{
    $logcatname = "Logcat_" + [string](Get-Date -Format 'yyyyMMdd_HHmmss') + ".txt"
    $ws = New-Object -ComObject WScript.Shell
    switch ( List_devices )
        {
            1 {
                switch ( $param )
                    {
                        {$param -eq "snap"}{$Log.Text = (Show_in_line (adb logcat -d -v time));break}
                        {$param -eq "clear"}{adb logcat -c;$Log.Text = "设备上的LogCat已清空。";$ws.popup("设备上的LogCat已清空。",0,$title,0 + 64);break}
                        {$param -eq "export"}{adb logcat -d -v time > $logcatname;$Log.Text = ("LogCat日志已导出。`n日志已导出至:`n" + (Get-Location) + "\" + $logcatname);$ws.popup("LogCat日志已导出",0,$title,0 + 64);break}
                        {$param -eq "trace"}{
                                                $trace_result = adb shell ls /data/anr

                                                if ($null -eq $trace_result)
                                                {
                                                    $Log.Text = "访问被拒绝，无权限。";break
                                                }

                                                for ($i = 0;$i -lt $trace_result.Length;$i++)
                                                {
                                                    if ($trace_result[$i].toString() -eq "traces.txt")
                                                    {
                                                        adb pull /data/anr/traces.txt
                                                        $Log.Text = ("ANR trace文件已导出。`n已导出至:`n" + (Get-Location) + "\traces.txt");$ws.popup("ANR trace文件已导出",0,$title,0 + 64);break
                                                    }
                                                    elseif ($trace_result[$i].toString() -eq "traces.txt.bugreport")
                                                    {
                                                        adb pull /data/anr/traces.txt.bugreport
                                                        $Log.Text = ("trace文件不存在，导出trace.txt.bugreport文件。`n已导出至:`n" + (Get-Location) + "\traces.txt.bugreport");$ws.popup("trace.txt.bugreport文件已导出",0,$title,0 + 64);break
                                                    }
                                                    else
                                                    {
                                                        $Log.Text = "trace文件不存在，请检查其是否生成或是否有相应权限。";break
                                                    }
                                                };break
                                            }
                        default{$Log.Text = "?????"}
                    };break
              }
            0 {$Log.Text = "没找到设备。";break}
            {$_ -ge 2} {$Log.Text = "连接了太多设备啦！";break}
        } 
    
}

Function FilterLog($keyword)
{
    switch ( List_devices )
    {
        1 {$Log.Text = (Show_in_line (adb logcat -d -v time | Where-Object {$_ -like "*" + $keyword + "*"}));break}
        0 {$Log.Text = "没找到设备。";break}
        {$_ -ge 2} {$Log.Text = "连接了太多设备啦！";break}
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
    $dialog.Title = '选择APK文件'
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
    $temp = Get-ChildItem $path
    $temp = $path.ToString() + "\" + $temp[$temp.Length-1].ToString() + "\"
    Set-Location $temp
    cmd /c "aapt d badging $filepath > $env:TMP\temp.txt"
    Set-Location $current

    $APK_path.Text = $filepath
    $APK_size.Text = ((Get-Item $filepath).Length).ToString() + " Byte"
    $APK_MD5.Text = GetMD5($filepath)

    $Package_name.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[1].Substring(5).Trim("'")
    $Version_code.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[2].Substring(12).Trim("'")
    $Version_name.Text = ((Get-Content $env:TMP\temp.txt)[0].split(" "))[3].Substring(12).Trim("'")
    
    
    if ($null -ne (Get-Content $env:TMP\temp.txt|findstr "sdkVersion:"))
    {
        $Min_sdk.Text = (Get-Content $env:TMP\temp.txt|findstr "sdkVersion:").Substring(11).Trim("'")
    }
    else
    {
        $Min_sdk.Text = "NA"
    }

    if ($null -ne (Get-Content $env:TMP\temp.txt | findstr "targetSdkVersion:"))
    {
        $Target_sdk.Text = (Get-Content $env:TMP\temp.txt | findstr "targetSdkVersion:").Substring(17).Trim("'")
    }
    else
    {
        $Target_sdk.Text = "NA"
    }

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
    $Author_label.Text = "作者：田晓东"

    $Version_label = New-Object System.Windows.Forms.Label
    $Version_label.Location = New-Object System.Drawing.Point(20,50)
    $Version_label.Size = New-Object System.Drawing.Size(200,20)
    $Version_label.Text = "版本： " + $Global:version

    $Name_label = New-Object System.Windows.Forms.Label
    $Name_label.Location = New-Object System.Drawing.Point(20,20)
    $Name_label.Size = New-Object System.Drawing.Size(200,20)
    $Name_label.Text = "PowerShell Tool Box"

    $OK_button = New-Object System.Windows.Forms.Button
    $OK_button.Text = "牛B!!"
    $OK_button.Location = New-Object System.Drawing.Point(200,60)
    $OK_button.Size = New-Object System.Drawing.Size(60,40)
    $OK_button.add_Click({$AboutForm.Close()})

    $HomePage_button = New-Object System.Windows.Forms.Button
    $HomePage_button.Text = "访问项目主页"
    $HomePage_button.Location = New-Object System.Drawing.Point(20,120)
    $HomePage_button.Size = New-Object System.Drawing.Size(100,30)
    $HomePage_button.add_Click({Start-Process -FilePath https://github.com/titan1983/PowerShellToolBox})

    $Mail_button = New-Object System.Windows.Forms.Button
    $Mail_button.Text = "发个邮件给作者"
    $Mail_button.Location = New-Object System.Drawing.Point(160,120)
    $Mail_button.Size = New-Object System.Drawing.Size(100,30)
    $Mail_button.add_Click({Start-Process -FilePath mailto:titan_1983@163.com?subject=[PowerShellToolBox]})

    $AboutForm.Controls.Add($OK_button)
    $AboutForm.Controls.Add($Author_label)
    $AboutForm.Controls.Add($Version_label)
    $AboutForm.Controls.Add($Name_label)
    $AboutForm.Controls.Add($HomePage_button)
    $AboutForm.Controls.Add($Mail_button)

    $AboutForm.ShowDialog()
}

Function RefreshEnv
{
    $Powershell_text.Text = $PSVersionTable.PSVersion

    $bh_path = Get-Item -Path $env:GOPATH\src\github.com\google\battery-historian
    $adb_version = cmd /c "adb version"
    $java_path = Get-Item -Path $env:JAVA_HOME
    $python_version = Get-Command python | Select-Object Version

    if ( $null -ne $bh_path )
    {
        $BatteryHistorian_text.Text = "已正确部署"
    }
    else
    {
        $BatteryHistorian_text.Text = "未正确部署Battery-Historian环境"
    }

    if ( $null -ne $adb_version )
    {
        $ADB_text.Text = $adb_version | findstr "Android Debug Bridge version"
    }
    else
    {
        $ADB_text.Text = "未正确设置ADB环境"
    }

    if ( $null -ne $java_path )
    {
        $Java_version = Get-Command java | Select-Object Version
        $Java_text.Text = $java_version.Version
    }
    else
    {
        $Java_text.Text = "未正确设置Java环境"
    }

    if ( $null -ne $python_version )
    {
        $Python_text.Text = $python_version.Version
    }
    else
    {
        $Python_text.Text = "未正确设置Python环境"
    }
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

    #这是个不可见的控件，是Tab页控件的容器，所以名称使用了小写开头。
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
    $Tab_env = New-Object System.Windows.Forms.TabPage
    #$Tab_CPU_MEM = New-Object System.Windows.Forms.TabPage

    $Tab_power.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_power.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_power.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_power.TabIndex = 0;
    $Tab_power.Text = "功耗评测相关";
    $Tab_power.UseVisualStyleBackColor = "true";

    $Tab_adb_tools.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_adb_tools.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_adb_tools.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_adb_tools.TabIndex = 0;
    $Tab_adb_tools.Text = "ADB常用工具";
    $Tab_adb_tools.UseVisualStyleBackColor = "true";

    $Tab_logcat.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_logcat.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_logcat.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_logcat.TabIndex = 0;
    $Tab_logcat.Text = "Logcat快照";
    $Tab_logcat.UseVisualStyleBackColor = "true";

    $Tab_option.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_option.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_option.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_option.TabIndex = 0;
    $Tab_option.Text = "手机模拟操作";
    $Tab_option.UseVisualStyleBackColor = "true";

    $Tab_apk_info.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_apk_info.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_apk_info.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_apk_info.TabIndex = 0;
    $Tab_apk_info.Text = "APK信息查询";
    $Tab_apk_info.UseVisualStyleBackColor = "true";
    $Tab_apk_info.AllowDrop = $True

    $Tab_env.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_env.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_env.Size = New-Object System.Drawing.Size(700, 400);
    $Tab_env.TabIndex = 0;
    $Tab_env.Text = "本地环境信息";
    $Tab_env.UseVisualStyleBackColor = "true";

    #以下为tab_power页的元素
    $Init_Button = New-Object System.Windows.Forms.Button
    $Init_Button.Location = New-Object System.Drawing.Point(560,40)
    $Init_Button.Size = New-Object System.Drawing.Size(120,40)
    $Init_Button.Text = "功耗评测初始化"
    $Init_Button.add_click( {Init_power} )

    $List_Button = New-Object System.Windows.Forms.Button
    $List_Button.Location = New-Object System.Drawing.Point(560,100)
    $List_Button.Size = New-Object System.Drawing.Size(120,40)
    $List_Button.Text = "已连接Android设备"
    $List_Button.add_click( {List_devices} )

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(560,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "导出Bugreport日志"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Run_batt_Button = New-Object System.Windows.Forms.Button
    $Run_batt_Button.Location = New-Object System.Drawing.Point(560,220)
    $Run_batt_Button.Size = New-Object System.Drawing.Size(120,40)
    $Run_batt_Button.Text = "运行`nBattery-Historian"
    $Run_batt_Button.add_click( {Run_battery_historian} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(500,340) 
    $Console.ReadOnly = $True
    $Console.Text = "执行结果显示在这里"
    $Console.WordWrap = $True
    $Console.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Console.BackColor = ([System.Drawing.Color]::Black)
    $Console.Font = New-Object System.Drawing.Font("Microsoft YaHei",16,[System.Drawing.FontStyle]::Regular)

    #以下为tab_adb_tools页的元素
    $Show_devices_info_Button = New-Object System.Windows.Forms.Button
    $Show_devices_info_Button.Location = New-Object System.Drawing.Point(560,40)
    $Show_devices_info_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_devices_info_Button.Text = "显示设备信息"
    $Show_devices_info_Button.add_click( {Show_devices_info} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(560,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "重启Android设备"
    $Reboot_Button.add_click( {Reboot} )

    $Connect_Button = New-Object System.Windows.Forms.Button
    $Connect_Button.Location = New-Object System.Drawing.Point(560,160)
    $Connect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Connect_Button.Text = "远程连接`nAndroid设备"
    $Connect_Button.add_click( {Connect_devices} )

    $Disconnect_Button = New-Object System.Windows.Forms.Button
    $Disconnect_Button.Location = New-Object System.Drawing.Point(560,220)
    $Disconnect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Disconnect_Button.Text = "断开所有远程设备"
    $Disconnect_Button.add_click( {Disconnect} )

    $ListPackage_Button = New-Object System.Windows.Forms.Button
    $Listpackage_Button.Location = New-Object System.Drawing.Point(560,280)
    $Listpackage_Button.Size = New-Object System.Drawing.Size(120,40)
    $Listpackage_Button.Text = "已安装应用列表"
    $Listpackage_Button.add_click( {ListPackage} )

    $Info = New-Object System.Windows.Forms.RichTextBox
    $Info.Location = New-Object System.Drawing.Point(20,40) 
    $Info.Size = New-Object System.Drawing.Size(500,340) 
    $Info.ReadOnly = $True
    $Info.Text = "你想看点啥？"
    $Info.WordWrap = $True
    $Info.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Info.BackColor = ([System.Drawing.Color]::Black)
    $Info.Font = New-Object System.Drawing.Font("Microsoft YaHei",16,[System.Drawing.FontStyle]::Regular)

    #以下为tab_logcat页的元素
    $Log = New-Object System.Windows.Forms.RichTextBox
    $Log.Location = New-Object System.Drawing.Point(20,60) 
    $Log.Size = New-Object System.Drawing.Size(650,280) 
    $Log.ReadOnly = $True
    $Log.Text = "==== LogCat快照 ===="
    $Log.WordWrap = $True
    $Log.ForeColor = ([System.Drawing.Color]::LawnGreen)
    $Log.BackColor = ([System.Drawing.Color]::Black)

    $Log_snap_Button = New-Object System.Windows.Forms.Button
    $Log_snap_Button.Location = New-Object System.Drawing.Point(20,10)
    $Log_snap_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_snap_Button.Text = "抓取LOGCAT快照"
    $Log_snap_Button.add_click( {Logcat "snap"} )

    $Log_clear_Button = New-Object System.Windows.Forms.Button
    $Log_clear_Button.Location = New-Object System.Drawing.Point(160,10)
    $Log_clear_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_clear_Button.Text = "清除LOGCAT日志"
    $Log_clear_Button.add_click( {Logcat "clear"} )

    $Log_export_Button = New-Object System.Windows.Forms.Button
    $Log_export_Button.Location = New-Object System.Drawing.Point(300,10)
    $Log_export_Button.Size = New-Object System.Drawing.Size(100,40)
    $Log_export_Button.Text = "导出LOGCAT日志"
    $Log_export_Button.add_click( {Logcat "export"} )

    $Trace_export_Button = New-Object System.Windows.Forms.Button
    $Trace_export_Button.Location = New-Object System.Drawing.Point(440,10)
    $Trace_export_Button.Size = New-Object System.Drawing.Size(100,40)
    $Trace_export_Button.Text = "导出trace文件"
    $Trace_export_Button.add_click( {Logcat "trace"} )

    $Clear_console_Button = New-Object System.Windows.Forms.Button
    $Clear_console_Button.Location = New-Object System.Drawing.Point(580,10)
    $Clear_console_Button.Size = New-Object System.Drawing.Size(100,40)
    $Clear_console_Button.Text = "清屏"
    $Clear_console_Button.add_click( {$Log.Text = "==== LogCat快照 ===="} )

    $Log_filter_Button = New-Object System.Windows.Forms.Button
    $Log_filter_Button.Location = New-Object System.Drawing.Point(20,340)
    $Log_filter_Button.Size = New-Object System.Drawing.Size(60,30)
    $Log_filter_Button.Text = "过滤"
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

    #以下为tab_option页的元素
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

    $Unlock_screen_Button = New-Object System.Windows.Forms.Button
    $Unlock_screen_Button.Location = New-Object System.Drawing.Point(520,240)
    $Unlock_screen_Button.Size = New-Object System.Drawing.Size(90,30)
    $Unlock_screen_Button.Text = "滑动解锁屏幕"
    $Unlock_screen_Button.add_click( {Press_key 62} )

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
    $Swipe_up_Button.Text = "向上滑动"
    $Swipe_up_Button.add_click( {Swipe_screen 500 800 500 200} )

    $Swipe_down_Button = New-Object System.Windows.Forms.Button
    $Swipe_down_Button.Location = New-Object System.Drawing.Point(200,200)
    $Swipe_down_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_down_Button.Text = "向下滑动"
    $Swipe_down_Button.add_click( {Swipe_screen 500 300 500 800} )

    $Swipe_left_Button = New-Object System.Windows.Forms.Button
    $Swipe_left_Button.Location = New-Object System.Drawing.Point(60,120)
    $Swipe_left_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_left_Button.Text = "向左滑动"
    $Swipe_left_Button.add_click( {Swipe_screen 500 500 100 500} )

    $Swipe_right_Button = New-Object System.Windows.Forms.Button
    $Swipe_right_Button.Location = New-Object System.Drawing.Point(340,120)
    $Swipe_right_Button.Size = New-Object System.Drawing.Size(100,40)
    $Swipe_right_Button.Text = "向右滑动"
    $Swipe_right_Button.add_click( {Swipe_screen 100 500 500 500} )

    $Screen_cap_Button = New-Object System.Windows.Forms.Button
    $Screen_cap_Button.Location = New-Object System.Drawing.Point(200,120)
    $Screen_cap_Button.Size = New-Object System.Drawing.Size(100,40)
    $Screen_cap_Button.Text = "屏幕截图"
    $Screen_cap_Button.add_click( {Screen_cap} )

    $Brightness_Max_Button = New-Object System.Windows.Forms.Button
    $Brightness_Max_Button.Location = New-Object System.Drawing.Point(520,280)
    $Brightness_Max_Button.Size = New-Object System.Drawing.Size(90,30)
    $Brightness_Max_Button.Text = "屏幕调至最亮"
    $Brightness_Max_Button.add_click( {SetBrightness 255} )


    $Brightness_Min_Button = New-Object System.Windows.Forms.Button
    $Brightness_Min_Button.Location = New-Object System.Drawing.Point(520,320)
    $Brightness_Min_Button.Size = New-Object System.Drawing.Size(90,30)
    $Brightness_Min_Button.Text = "屏幕调至最暗"
    $Brightness_Min_Button.add_click( {SetBrightness 1} )


    $Warning_label = New-Object System.Windows.Forms.Label
    $Warning_label.Location = New-Object System.Drawing.Point(20,10)
    $Warning_label.Size = New-Object System.Drawing.Size(300,40)
    $Warning_label.Text = ""
    $Warning_label.ForeColor = "Red"
    $Warning_label.Font = New-Object System.Drawing.Font("Tahoma",12,[System.Drawing.FontStyle]::Bold)

    #以下为tab_apk_info页的元素
    $OpenFile_button = New-Object System.Windows.Forms.Button
    $OpenFile_button.Location = New-Object System.Drawing.Point(580,300)
    $OpenFile_button.Size = New-Object System.Drawing.Size(90,40)
    $OpenFile_button.Text = "打开APK文件"
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
    $APK_name_label.Text = "应用名称："

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
    $APK_path_label.Text = "APK路径："

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
    $APK_size_label.Text = "APK文件大小："

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
    $Package_name_label.Text = "APK包名："

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
    $Version_name_label.Text = "Version Name："

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
    $Version_code_label.Text = "Version Code："

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
    $Target_sdk_label.Text = "适配系统等级："

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
    $Min_sdk_label.Text = "最低系统等级："

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
    $APK_MD5_label.Text = "MD5："

    $APK_info_Button = New-Object System.Windows.Forms.Button
    $APK_info_Button.Location = New-Object System.Drawing.Point(580,220)
    $APK_info_Button.Size = New-Object System.Drawing.Size(90,40)
    $APK_info_Button.Text = "查看详细信息"
    $APK_info_Button.add_click( {ShowDetail} )
    $APK_info_Button.Enabled = $false

    #以下为tab_env页的元素
    $Env_Button = New-Object System.Windows.Forms.Button
    $Env_Button.Location = New-Object System.Drawing.Point(520,30)
    $Env_Button.Size = New-Object System.Drawing.Size(120,40)
    $Env_Button.Text = "刷新本地环境数据"
    $Env_Button.add_click( {RefreshEnv} )

    $Powershell_text = New-Object System.Windows.Forms.TextBox
    $Powershell_text.Location = New-Object System.Drawing.Point(160,25)
    $Powershell_text.Size = New-Object System.Drawing.Size(300,25)
    $Powershell_text.ReadOnly = $True
    $Powershell_text.Text = ""
    $Powershell_text.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Powershell_text.ForeColor = "#370fa5"

    $Powershell_label = New-Object System.Windows.Forms.Label
    $Powershell_label.Location = New-Object System.Drawing.Point(22,25)
    $Powershell_label.Size = New-Object System.Drawing.Size(120,25)
    $Powershell_label.Text = "PowerShell 版本："

    $ADB_text = New-Object System.Windows.Forms.TextBox
    $ADB_text.Location = New-Object System.Drawing.Point(160,65)
    $ADB_text.Size = New-Object System.Drawing.Size(300,25)
    $ADB_text.ReadOnly = $True
    $ADB_text.Text = ""
    $ADB_text.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $ADB_text.ForeColor = "#370fa5"

    $ADB_label = New-Object System.Windows.Forms.Label
    $ADB_label.Location = New-Object System.Drawing.Point(22,65)
    $ADB_label.Size = New-Object System.Drawing.Size(120,25)
    $ADB_label.Text = "ADB 版本："

    $Java_text = New-Object System.Windows.Forms.TextBox
    $Java_text.Location = New-Object System.Drawing.Point(160,105)
    $Java_text.Size = New-Object System.Drawing.Size(300,25)
    $Java_text.ReadOnly = $True
    $Java_text.Text = ""
    $Java_text.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Java_text.ForeColor = "#370fa5"

    $Java_label = New-Object System.Windows.Forms.Label
    $Java_label.Location = New-Object System.Drawing.Point(22,105)
    $Java_label.Size = New-Object System.Drawing.Size(120,25)
    $Java_label.Text = "Java 版本："

    $BatteryHistorian_text = New-Object System.Windows.Forms.TextBox
    $BatteryHistorian_text.Location = New-Object System.Drawing.Point(160,145)
    $BatteryHistorian_text.Size = New-Object System.Drawing.Size(300,25)
    $BatteryHistorian_text.ReadOnly = $True
    $BatteryHistorian_text.Text = ""
    $BatteryHistorian_text.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $BatteryHistorian_text.ForeColor = "#370fa5"

    $BatteryHistorian_label = New-Object System.Windows.Forms.Label
    $BatteryHistorian_label.Location = New-Object System.Drawing.Point(22,145)
    $BatteryHistorian_label.Size = New-Object System.Drawing.Size(120,25)
    $BatteryHistorian_label.Text = "Battery-Historian："

    $Python_text = New-Object System.Windows.Forms.TextBox
    $Python_text.Location = New-Object System.Drawing.Point(160,185)
    $Python_text.Size = New-Object System.Drawing.Size(300,25)
    $Python_text.ReadOnly = $True
    $Python_text.Text = ""
    $Python_text.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $Python_text.ForeColor = "#370fa5"

    $Python_label = New-Object System.Windows.Forms.Label
    $Python_label.Location = New-Object System.Drawing.Point(22,185)
    $Python_label.Size = New-Object System.Drawing.Size(120,25)
    $Python_label.Text = "Python 版本："

    #以下为主窗体显示元素
    $Time_label = New-Object System.Windows.Forms.Label
    $Time_label.Location = New-Object System.Drawing.Point(20,450)
    $Time_label.Size = New-Object System.Drawing.Size(400,20)
    $Time_label.Text = "工具启动于：" + (Get-Date -Format "yyyy年M月dd日 dddd HH:mm:ss")
    $Time_label.Font = New-Object System.Drawing.Font("Microsoft YaHei",10,[System.Drawing.FontStyle]::Regular)

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(580,420)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "退出"
    $Exit_Button.add_click( {$MainForm.Close()} )

    $About_Button = New-Object System.Windows.Forms.Button
    $About_Button.Location = New-Object System.Drawing.Point(500,420)
    $About_Button.Size = New-Object System.Drawing.Size(60,40)
    $About_Button.Text = "关于"
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
    $tabControl.Controls.Add($Tab_env)
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
    $Tab_adb_tools.Controls.Add($Listpackage_Button)

    $Tab_logcat.Controls.Add($Log_filter_Button)
    $Tab_logcat.Controls.Add($Log)
    $Tab_logcat.Controls.Add($Log_snap_Button)
    $Tab_logcat.Controls.Add($Log_clear_Button)
    $Tab_logcat.Controls.Add($Log_export_Button)
    $Tab_logcat.Controls.Add($Trace_export_Button)
    $Tab_logcat.Controls.Add($Filter_box)
    $Tab_logcat.Controls.Add($Clear_console_Button)

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
    $Tab_option.Controls.Add($Unlock_screen_Button)

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

    $Tab_env.Controls.Add($Env_Button)
    $Tab_env.Controls.Add($Powershell_text)
    $Tab_env.Controls.Add($Powershell_label)
    $Tab_env.Controls.Add($Java_text)
    $Tab_env.Controls.Add($Java_label)
    $Tab_env.Controls.Add($ADB_text)
    $Tab_env.Controls.Add($ADB_label)
    $Tab_env.Controls.Add($BatteryHistorian_text)
    $Tab_env.Controls.Add($BatteryHistorian_label)
    $Tab_env.Controls.Add($Python_text)
    $Tab_env.Controls.Add($Python_label)

    $MainForm.Add_Shown({$MainForm.Activate()})
    $MainForm.ShowDialog()
}

StartUp