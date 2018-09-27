#Created by Tian Xiaodong
#请将脚本文件保存为ANSI编码格式，否则无法正常输出中文字符。

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Global Define
$Global:title = "PowerShell 懒人工具"
$Global:version = "1.0.0"

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
                $list_devices = adb devices

                switch ( ($list_devices) )
                {
                    {($list_devices[1].Contains( ":" ))}{$Console.Text = "远程设备，不予以初始化。";break}
                    {($list_devices[1].Contains("unauthorized"))}{$Console.Text = "设备未授权。";break}
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
                        $Console.Text = "初始化失败，请检查手机连接或ADB环境。"
                    }
                    ;break
                }
               }
              ;break}
            0 { $Console.Text = "没找到设备。";break }
            {$_ -ge 2} { $Console.Text = "连接了太多Android设备啦！";break }
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
#当前目录为根目录时也不导出，因为bugreport工具不支持在根目录下导出，这个不是我的BUG，是bugreport的BUG。
{
    $rootD_flag = isRootDirectory
    if ( $rootD_flag -eq 0 )
    {
        switch ( ( $device_count = List_devices ) )
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
                            ;break
                         }
                    }
                }
                catch [System.Exception]
                {
                    $Console.Text = "执行失败，请检查手机连接或ADB环境。"
                }
                ;break
              }
            0 { $Console.Text = "没找到设备。";break }
            {$_ -ge 2 } { $Console.Text = "连接了太多设备啦！`n导出时电脑上只能连接一台Android设备。";break }
        }
    }
    else
    {
        $Console.Text = "当前目录为根目录，无法导出。`n因为bugreport工具不支持在根目录下导出。`n这个不是我的BUG，是bugreport的BUG。`n解决方案是：把本工具放在非根目录的目录下运行。"
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

Function Show_devices_info
{
    switch ( ( $device_count = List_devices ) )
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
                    $Get_manuf = adb shell getprop ro.product.manufacturer
                    $Get_model = adb shell getprop ro.product.model
                    $Get_CPU = adb shell cat /proc/cpuinfo | findstr " Hardware"
                    $Get_Mem = adb shell cat /proc/meminfo | findstr " MemTotal"
                    $Info.Text = "Android版本: " + $Get_android_ver + "`nAndroid API: " + $Get_android_API + "`n屏幕分辨率: " + $Get_screen_res + "`n制造商: " + $Get_manuf + "`n型号: " +$Get_model + "`nCPU: " + $Get_CPU.Substring(11) + "`n物理内存: " + $Get_Mem.Substring(11).trim()
                }
                catch [System.Exception]
                {
                    $Info.Text = "执行失败，请检查手机连接或ADB环境。"
                }
            }
            ;break
          }
        0 { $Info.Text = "没找到设备。";break }
        {$_ -ge 2 } { $Info.Text = "连了这么多台设备，我哪知道要查哪个。";break }
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
                $Info.Text = "已重启，请检查设备。";break
              }
            0 { $Info.Text = "没找到设备。";break }
            {$_ -ge 2} {$Info.Text = "连接了太多设备啦！没法重启。";break}
        }       
    }
    else
    {
        $Info.Text = "好好好，不重启了。"
    }
}

Function isRootDirectory
{
    $path_per = Get-Location
    cd /
    $path_after = Get-Location

    if ( [String]($path_per) -eq [String]($path_after) )
    {
        return 1
    }
    else
    {
        cd $path_per
        return 0
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
    $Port.Size = New-Object System.Drawing.Size(30,20) 
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
                    $wsr = $ws.popup("已连接成功。",0,$title,0 + 64)
                    $ConnectForm.Close()
                }
                else
                {
                    $Info.Text = "连接失败，请检查IP地址、端口号或WIFI设置。"
                    $wsr = $ws.popup("连接失败，请检查IP地址、端口号或WIFI设置。",0,$title,0 + 64)
                }
            }
            else
            {
                $Info.Text = "请填写正确格式的端口号。"
                
	            $wsr = $ws.popup("请填写正确格式的端口号。",0,$title,0 + 64)
            }
        }
        else
        {
            $Info.Text = "请填写正确格式的IP地址。"
            $ws = New-Object -ComObject WScript.Shell
	        $wsr = $ws.popup("请填写正确格式的IP地址。",0,$title,0 + 64)
        }
    }
    else
    {
        $Info.Text = "IP地址未填写。"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("IP地址未填写。",0,$title,0 + 64)
    }
}

Function Disconnect
{
    try
    {
        adb disconnect
        $Info.Text = "所有连接的远程设备均已断开。"
        $ws = New-Object -ComObject WScript.Shell
	    $wsr = $ws.popup("所有连接的远程设备均已断开。",0,$title,0 + 64)
    }
    catch [System.Exception]
    {
        $Info.Text = "断开异常。"
    }
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

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(360,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "导出Bugreport日志"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Run_batt_Button = New-Object System.Windows.Forms.Button
    $Run_batt_Button.Location = New-Object System.Drawing.Point(360,220)
    $Run_batt_Button.Size = New-Object System.Drawing.Size(120,40)
    $Run_batt_Button.Text = "运行`nBattery-Historian"
    $Run_batt_Button.add_click( {Run_battery_historian} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(300,240) 
    $Console.ReadOnly = $True
    $Console.Text = "执行结果显示在这里"
    $Console.WordWrap = $True


    #以下为tab_adb_tools页的元素
    $Show_devices_info_Button = New-Object System.Windows.Forms.Button
    $Show_devices_info_Button.Location = New-Object System.Drawing.Point(360,40)
    $Show_devices_info_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_devices_info_Button.Text = "显示设备信息"
    $Show_devices_info_Button.add_click( {Show_devices_info} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(360,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "重启Android设备"
    $Reboot_Button.add_click( {Reboot} )

    $Connect_Button = New-Object System.Windows.Forms.Button
    $Connect_Button.Location = New-Object System.Drawing.Point(360,160)
    $Connect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Connect_Button.Text = "远程连接`nAndroid设备"
    $Connect_Button.add_click( {Connect_devices} )

    $Disconnect_Button = New-Object System.Windows.Forms.Button
    $Disconnect_Button.Location = New-Object System.Drawing.Point(360,220)
    $Disconnect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Disconnect_Button.Text = "断开所有远程设备"
    $Disconnect_Button.add_click( {Disconnect} )

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
    $Time_label.Text = "工具启动于：" + (Get-Date -Format "yyyy年M月dd日 dddd HH:mm:ss")

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(380,330)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "退出"
    $Exit_Button.add_click( { $MainForm.Close() } )

    $About_Button = New-Object System.Windows.Forms.Button
    $About_Button.Location = New-Object System.Drawing.Point(300,330)
    $About_Button.Size = New-Object System.Drawing.Size(60,40)
    $About_Button.Text = "关于"
    $About_Button.add_click( { About } )

    $MainForm.Controls.Add($Exit_Button)
    $MainForm.Controls.Add($About_Button)
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

    $Tab_adb_tools.Controls.Add($Show_devices_info_Button)
    $Tab_adb_tools.Controls.Add($Info)
    $Tab_adb_tools.Controls.Add($Reboot_Button)
    $Tab_adb_tools.Controls.Add($Connect_Button)
    $Tab_adb_tools.Controls.Add($Disconnect_Button)

    $MainForm.Add_Shown({$MainForm.Activate()})
    $result = $MainForm.ShowDialog()
}

StartUp