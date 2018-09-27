#Created by Tian Xiaodong
#�뽫�ű��ļ�����ΪANSI�����ʽ�������޷�������������ַ���

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Global Define
$Global:title = "PowerShell ���˹���"
$Global:version = "1.0.0"

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
            0 { $Console.Text = "û�ҵ��豸��";break }
            {$_ -ge 2} { $Console.Text = "������̫��Android�豸����";break }
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
#��ǰĿ¼Ϊ��Ŀ¼ʱҲ����������Ϊbugreport���߲�֧���ڸ�Ŀ¼�µ�������������ҵ�BUG����bugreport��BUG��
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
                        {$list_devices[1].Contains( ":" )}{$Console.Text = "Զ���豸�������Ե�����־��";break}
                        {$list_devices[1].Contains( "unauthorized" )}{$Console.Text = "�豸δ��Ȩ��";break}
                        default
                        {
                            $Console.Text = "���ڵ������˹��̻��ʱ�����ӣ������ĵȴ���`n�������ǰ�����߲��ɵ����"

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
                            $ws = New-Object -ComObject WScript.Shell
                            $wsi = $ws.popup(��������ɣ���,0,$title,0 + 64)
                            ;break
                         }
                    }
                }
                catch [System.Exception]
                {
                    $Console.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
                }
                ;break
              }
            0 { $Console.Text = "û�ҵ��豸��";break }
            {$_ -ge 2 } { $Console.Text = "������̫���豸����`n����ʱ������ֻ������һ̨Android�豸��";break }
        }
    }
    else
    {
        $Console.Text = "��ǰĿ¼Ϊ��Ŀ¼���޷�������`n��Ϊbugreport���߲�֧���ڸ�Ŀ¼�µ�����`n��������ҵ�BUG����bugreport��BUG��`n��������ǣ��ѱ����߷��ڷǸ�Ŀ¼��Ŀ¼�����С�"
    }
}

Function Run_battery_historian
{

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
                    $Get_manuf = adb shell getprop ro.product.manufacturer
                    $Get_model = adb shell getprop ro.product.model
                    $Get_CPU = adb shell cat /proc/cpuinfo | findstr " Hardware"
                    $Get_Mem = adb shell cat /proc/meminfo | findstr " MemTotal"
                    $Info.Text = "Android�汾: " + $Get_android_ver + "`nAndroid API: " + $Get_android_API + "`n��Ļ�ֱ���: " + $Get_screen_res + "`n������: " + $Get_manuf + "`n�ͺ�: " +$Get_model + "`nCPU: " + $Get_CPU.Substring(11) + "`n�����ڴ�: " + $Get_Mem.Substring(11).trim()
                }
                catch [System.Exception]
                {
                    $Info.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
                }
            }
            ;break
          }
        0 { $Info.Text = "û�ҵ��豸��";break }
        {$_ -ge 2 } { $Info.Text = "������ô��̨�豸������֪��Ҫ���ĸ���";break }
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
                adb reboot
                $Info.Text = "�������������豸��";break
              }
            0 { $Info.Text = "û�ҵ��豸��";break }
            {$_ -ge 2} {$Info.Text = "������̫���豸����û��������";break}
        }       
    }
    else
    {
        $Info.Text = "�úúã��������ˡ�"
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
    $IP_label.Text = "��������ȷ��ʽ��IP��ַ��"

    $Port_label = New-Object System.Windows.Forms.Label
    $Port_label.Location = New-Object System.Drawing.Point(10,70)
    $Port_label.Size = New-Object System.Drawing.Size(300,20)
    $Port_label.Text = "��������ȷ��ʽ�Ķ˿ںţ���ѡ����"

    $Port = New-Object System.Windows.Forms.TextBox
    $Port.Location = New-Object System.Drawing.Point(15,90) 
    $Port.Size = New-Object System.Drawing.Size(30,20) 
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
    $MainForm.Size = New-Object System.Drawing.Size(520,420) 
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
    $tabControl.Size = New-Object System.Drawing.Size(500, 400);
    $tabControl.TabIndex = 0

    $Tab_power = New-Object System.Windows.Forms.TabPage
    $Tab_adb_tools = New-Object System.Windows.Forms.TabPage
    $Tab_logcat = New-Object System.Windows.Forms.TabPage

    $Tab_power.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_power.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_power.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_power.TabIndex = 0;
    $Tab_power.Text = "�����������";
    $Tab_power.UseVisualStyleBackColor = "true";

    $Tab_adb_tools.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_adb_tools.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_adb_tools.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_adb_tools.TabIndex = 0;
    $Tab_adb_tools.Text = "ADB���ù���";
    $Tab_adb_tools.UseVisualStyleBackColor = "true";

    $Tab_logcat.Location = New-Object System.Drawing.Point(4, 22);
    $Tab_logcat.Padding = New-Object System.Windows.Forms.Padding(3);
    $Tab_logcat.Size = New-Object System.Drawing.Size(500, 400);
    $Tab_logcat.TabIndex = 0;
    $Tab_logcat.Text = "Logcat����";
    $Tab_logcat.UseVisualStyleBackColor = "true";


    #����Ϊtab_powerҳ��Ԫ��
    $Init_Button = New-Object System.Windows.Forms.Button
    $Init_Button.Location = New-Object System.Drawing.Point(360,40)
    $Init_Button.Size = New-Object System.Drawing.Size(120,40)
    $Init_Button.Text = "���������ʼ��"
    $Init_Button.add_click( {Init_power} )

    $List_Button = New-Object System.Windows.Forms.Button
    $List_Button.Location = New-Object System.Drawing.Point(360,100)
    $List_Button.Size = New-Object System.Drawing.Size(120,40)
    $List_Button.Text = "������Android�豸"
    $List_Button.add_click( {List_devices} )

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(360,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "����Bugreport��־"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Run_batt_Button = New-Object System.Windows.Forms.Button
    $Run_batt_Button.Location = New-Object System.Drawing.Point(360,220)
    $Run_batt_Button.Size = New-Object System.Drawing.Size(120,40)
    $Run_batt_Button.Text = "����`nBattery-Historian"
    $Run_batt_Button.add_click( {Run_battery_historian} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(300,240) 
    $Console.ReadOnly = $True
    $Console.Text = "ִ�н����ʾ������"
    $Console.WordWrap = $True


    #����Ϊtab_adb_toolsҳ��Ԫ��
    $Show_devices_info_Button = New-Object System.Windows.Forms.Button
    $Show_devices_info_Button.Location = New-Object System.Drawing.Point(360,40)
    $Show_devices_info_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_devices_info_Button.Text = "��ʾ�豸��Ϣ"
    $Show_devices_info_Button.add_click( {Show_devices_info} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(360,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "����Android�豸"
    $Reboot_Button.add_click( {Reboot} )

    $Connect_Button = New-Object System.Windows.Forms.Button
    $Connect_Button.Location = New-Object System.Drawing.Point(360,160)
    $Connect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Connect_Button.Text = "Զ������`nAndroid�豸"
    $Connect_Button.add_click( {Connect_devices} )

    $Disconnect_Button = New-Object System.Windows.Forms.Button
    $Disconnect_Button.Location = New-Object System.Drawing.Point(360,220)
    $Disconnect_Button.Size = New-Object System.Drawing.Size(120,40)
    $Disconnect_Button.Text = "�Ͽ�����Զ���豸"
    $Disconnect_Button.add_click( {Disconnect} )

    $Info = New-Object System.Windows.Forms.RichTextBox
    $Info.Location = New-Object System.Drawing.Point(20,40) 
    $Info.Size = New-Object System.Drawing.Size(300,200) 
    $Info.ReadOnly = $True
    $Info.Text = "���뿴��ɶ��"
    $Info.WordWrap = $True


    #����Ϊ��������ʾԪ��
    $Time_label = New-Object System.Windows.Forms.Label
    $Time_label.Location = New-Object System.Drawing.Point(20,360)
    $Time_label.Size = New-Object System.Drawing.Size(280,20)
    $Time_label.Text = "���������ڣ�" + (Get-Date -Format "yyyy��M��dd�� dddd HH:mm:ss")

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(380,330)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "�˳�"
    $Exit_Button.add_click( { $MainForm.Close() } )

    $About_Button = New-Object System.Windows.Forms.Button
    $About_Button.Location = New-Object System.Drawing.Point(300,330)
    $About_Button.Size = New-Object System.Drawing.Size(60,40)
    $About_Button.Text = "����"
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