#Created by Tian Xiaodong
#请将脚本文件保存为ANSI编码格式，否则无法正常输出中文字符。

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Global Define
$title = "PowerShell 懒人工具"

Function Init_power
{
    $warning = "即将开始功耗评测初始化，点击OK键继续，点击Cancel键退出。`nInitial is coming, press `"OK`" to continue, or press `"Cancel`" to abort."
    $done = "初始化完成，请尽快完成评测。`nDone, please do the evaluation ASAP."

    $ws = New-Object -ComObject WScript.Shell
    $wsr = $ws.popup($warning,0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( ( $device_count = List_devices ) )
	    {
            1 {   
                $init_1 = adb shell dumpsys batterystats --reset
                $init_2 = adb shell dumpsys batterystats --enable full-wake-history
        
                if ( ( $init_1 -ne $null ) -or ( $init_2 -ne $null ) )
                {
                    $Console.Text = [string]$init_1 + "`n" + [string]$init_2
                    $wsi = $ws.popup($done,0,$title,0 + 64)
                }
                else
                {
                    $Console.Text = "初始化失败，请检查手机连接或ADB环境。"
                }
              }
            0 { $Console.Text = "没找到设备。" }
            {$_ -ge 2} { $Console.Text = "连接了太多Android设备啦！" }
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
    $list_devices = adb devices

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
    switch ( ( $device_count = List_devices ) )
    {
        1 {
            try
            {
                $list_devices = adb devices

                if ( $list_devices[1].Contains( ":" )  )
                {
                    $Console.Text = "远程设备，不予以导出日志。"
                }
                else
                {
                    $Console.Text = "正在导出，此过程会耗时数分钟，请耐心等待。`n导出完成前本工具不可点击。"

                    if ( ( $Get_android_API = adb shell getprop ro.build.version.sdk ) -ge 24 )
                    {
                        adb bugreport
                    }
                    else
                    {
                        $filename = "Bugreport_" + [string](Get-Date -Format 'yyyyMMd_Hms') + ".txt"
                        adb bugreport > $filename
                    }
                    $Console.Text = “导出完成！`n” + "Bugreport日志文件已存放于：`n" + ( Get-Location )
                    $ws = New-Object -ComObject WScript.Shell
                    $wsi = $ws.popup(“导出完成！”,0,$title,0 + 64)
                }
            }
            catch [System.Exception]
            {
                $Console.Text = "执行失败，请检查手机连接或ADB环境。"
            }
          }
        0 { $Console.Text = "没找到设备。" }
        {$_ -ge 2 } { $Console.Text = "连接了太多设备啦！`n导出时电脑上只能连接一台Android设备。" }
    }
}

Function Run_battery_historian
{

    if ( get-process | where-object {$_.Name -eq "battery-historian"} )
    {
	    write-host "Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/" -ForegroundColor Red
        $Console.Text = "Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("Battery-Historian 已经在运行了。`n`n请访问 http://localhost:9999/",0,"PowerShell 懒人工具系列",0 + 64)
        Start-Process -FilePath http://localhost:9999/
    }

    else
    {
        $Console.Text = "Battery Historian 正在运行。`n请访问 http://localhost:9999/"
	    $path = Get-Item -Path $env:GOPATH\src\github.com\google\battery-historian
	    
        if ( $path -ne $null )
        {
            cd $path
            Start-Process powershell.exe -ArgumentList "write-host Battery Historian 正在运行，请不要关闭此窗口。 -ForegroundColor Yellow `ngo run cmd/battery-historian/battery-historian.go" -WindowStyle Minimized
        }
        else
        {
            $Console.Text = "工具都没装你运行个毛线！"
        }
    }
}

Function Show_android_version
{
    switch ( ( $device_count = List_devices ) )
    {
        1 {
            try
            {
                $Get_android_ver = adb shell getprop ro.build.version.release
                $Get_android_API = adb shell getprop ro.build.version.sdk
                $Info.Text = "Android版本: " + $Get_android_ver + "`nAndroid API: " + $Get_android_API
            }
            catch [System.Exception]
            {
                $Info.Text = "执行失败，请检查手机连接或ADB环境。"
            }
          }
        0 { $Info.Text = "没找到设备。" }
        {$_ -ge 2 } { $Info.Text = "连了这么多台设备，我哪知道要查哪个。" }
    }
}

Function Reboot
{
    $ws = New-Object -ComObject WScript.Shell
    $wsr = $ws.popup("即将重启设备，确定要继续？",0,$title,1 + 64)

    if ( $wsr -eq 1 )
    {
        switch ( ( $device_count = List_devices ) )
        {
            1 {
                adb reboot
                $Info.Text = "已重启，请检查设备。"
             }
            0 { $Info.Text = "没找到设备。" }
            {$_ -ge 2} {$Info.Text = "连接了太多设备啦！没法重启。"}
        }       
    }
    else
    {
        $Info.Text = "好好好，不重启了。"
    }
}


Function StartUp
{
    $MainForm = New-Object System.Windows.Forms.Form
    $MainForm.Text = $title
    $MainForm.Size = New-Object System.Drawing.Size(520,420) 
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
    $tabControl.Size = New-Object System.Drawing.Size(500, 400);
    $tabControl.TabIndex = 0

    $Tab_power = New-Object System.Windows.Forms.TabPage
    $Tab_adb_tools = New-Object System.Windows.Forms.TabPage
    $Tab_logcat = New-Object System.Windows.Forms.TabPage

    $Tab_power.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_power.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_power.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_power.TabIndex = 0;
    $Tab_power.Text = "功耗评测相关";
    $Tab_power.UseVisualStyleBackColor = "true";

    $Tab_adb_tools.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_adb_tools.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_adb_tools.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_adb_tools.TabIndex = 0;
    $Tab_adb_tools.Text = "ADB常用工具";
    $Tab_adb_tools.UseVisualStyleBackColor = "true";

    $Tab_logcat.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_logcat.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_logcat.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_logcat.TabIndex = 0;
    $Tab_logcat.Text = "Logcat快照";
    $Tab_logcat.UseVisualStyleBackColor = "true";


    #以下为tab_power页的元素
    $Init_Button = New-Object System.Windows.Forms.Button
    $Init_Button.Location = New-Object System.Drawing.Point(360,40)
    $Init_Button.Size = New-Object System.Drawing.Size(120,40)
    $Init_Button.Text = "功耗评测初始化"
    $Init_Button.add_click( {Init_power} )

    $List_Button = New-Object System.Windows.Forms.Button
    $List_Button.Location = New-Object System.Drawing.Point(360,100)
    $List_Button.Size = New-Object System.Drawing.Size(120,40)
    $List_Button.Text = "已连接Android设备"
    $List_Button.add_click( {List_devices} )

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(380,320)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "退出"
    $Exit_Button.add_click( { $MainForm.Close() } )

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(360,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "导出Bugreport日志"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Run_batt_Button = New-Object System.Windows.Forms.Button
    $Run_batt_Button.Location = New-Object System.Drawing.Point(360,220)
    $Run_batt_Button.Size = New-Object System.Drawing.Size(120,40)
    $Run_batt_Button.Text = "运行Battery Historian"
    $Run_batt_Button.add_click( {Run_battery_historian} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(300,240) 
    $Console.ReadOnly = $True
    $Console.Text = "执行结果显示在这里"
    $Console.WordWrap = $True

    #以下为tab_adb_tools页的元素
    $Show_android_version_Button = New-Object System.Windows.Forms.Button
    $Show_android_version_Button.Location = New-Object System.Drawing.Point(360,40)
    $Show_android_version_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_android_version_Button.Text = "显示Android版本"
    $Show_android_version_Button.add_click( {Show_android_version} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(360,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "重启Android设备"
    $Reboot_Button.add_click( {Reboot} )

    $Info = New-Object System.Windows.Forms.RichTextBox
    $Info.Location = New-Object System.Drawing.Point(20,40) 
    $Info.Size = New-Object System.Drawing.Size(300,200) 
    $Info.ReadOnly = $True
    $Info.Text = "你想看点啥？"
    $Info.WordWrap = $True

    #以下为主窗体显示元素
    $Time_label = New-Object System.Windows.Forms.Label
    $Time_label.Location = New-Object System.Drawing.Point(20,360)
    $Time_label.Size = New-Object System.Drawing.Size(280,20)
    $Time_label.Text = "工具启动于：" + (Get-Date -Format "yyyy年M月d日 dddd H:m:s")

    $MainForm.Controls.Add($Exit_Button)
    $MainForm.Controls.Add($Time_label)
    $MainForm.Controls.Add($tabControl)

    $tabControl.Controls.Add($Tab_power)
    $tabControl.Controls.Add($Tab_adb_tools)
    #$tabControl.Controls.Add($Tab_logcat)

    $Tab_power.Controls.Add($Export_bugreport_Button)
    $Tab_power.Controls.Add($Init_Button)
    $Tab_power.Controls.Add($Console)
    $Tab_power.Controls.Add($List_Button)
    $Tab_power.Controls.Add($Run_batt_Button)

    $Tab_adb_tools.Controls.Add($Show_android_version_Button)
    $Tab_adb_tools.Controls.Add($Info)
    $Tab_adb_tools.Controls.Add($Reboot_Button)

    $result = $MainForm.ShowDialog()
}

StartUp
