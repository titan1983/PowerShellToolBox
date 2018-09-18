#Created by Tian Xiaodong
#�뽫�ű��ļ�����ΪANSI�����ʽ�������޷�������������ַ���

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Global Define
$title = "PowerShell ���˹���"

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
              }
            0 { $Console.Text = "û�ҵ��豸��" }
            {$_ -ge 2} { $Console.Text = "������̫��Android�豸����" }
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
        $Console.Text = $temp + "`n��ǰ�����ӡ� + ($list_devices.Count-2) + ��̨Android�豸��" + "`n���а����� + ��$wireless_count�� + ��̨���������豸��"
        return [int]( $list_devices.Count - 2 )
    }
    else
    {
        $Console.Text = "ִ��ʧ�ܣ�����ADB������"
    }
}

Function Export_bugreport
{
    switch ( ( $device_count = List_devices ) )
    {
        1 {
            try
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
            }
            catch [System.Exception]
            {
                $Console.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
            }
          }
        0 { $Console.Text = "û�ҵ��豸��" }
        {$_ -ge 2 } { $Console.Text = "������̫���豸����`n����ʱ������ֻ������һ̨Android�豸��" }
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
                $Info.Text = "Android�汾: " + $Get_android_ver + "`nAndroid API: " + $Get_android_API
            }
            catch [System.Exception]
            {
                $Info.Text = "ִ��ʧ�ܣ������ֻ����ӻ�ADB������"
            }
          }
        0 { $Info.Text = "û�ҵ��豸��" }
        {$_ -ge 2 } { $Info.Text = "������ô��̨�豸������֪��Ҫ���ĸ���" }
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
                $Info.Text = "�������������豸��"
             }
            0 { $Info.Text = "û�ҵ��豸��" }
            {$_ -ge 2} {$Info.Text = "������̫���豸����û��������"}
        }       
    }
    else
    {
        $Info.Text = "�úúã��������ˡ�"
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

    $Exit_Button = New-Object System.Windows.Forms.Button
    $Exit_Button.Location = New-Object System.Drawing.Point(380,320)
    $Exit_Button.Size = New-Object System.Drawing.Size(90,40)
    $Exit_Button.Text = "�˳�"
    $Exit_Button.add_click( { $MainForm.Close() } )

    $Export_bugreport_Button = New-Object System.Windows.Forms.Button
    $Export_bugreport_Button.Location = New-Object System.Drawing.Point(360,160)
    $Export_bugreport_Button.Size = New-Object System.Drawing.Size(120,40)
    $Export_bugreport_Button.Text = "����Bugreport��־"
    $Export_bugreport_Button.add_click( {Export_bugreport} )

    $Console = New-Object System.Windows.Forms.RichTextBox
    $Console.Location = New-Object System.Drawing.Point(20,40) 
    $Console.Size = New-Object System.Drawing.Size(300,240) 
    $Console.ReadOnly = $True
    $Console.Text = "ִ�н����ʾ������"
    $Console.WordWrap = $True

    #����Ϊtab_adb_toolsҳ��Ԫ��
    $Show_android_version_Button = New-Object System.Windows.Forms.Button
    $Show_android_version_Button.Location = New-Object System.Drawing.Point(360,40)
    $Show_android_version_Button.Size = New-Object System.Drawing.Size(120,40)
    $Show_android_version_Button.Text = "��ʾAndroid�汾"
    $Show_android_version_Button.add_click( {Show_android_version} )

    $Reboot_Button = New-Object System.Windows.Forms.Button
    $Reboot_Button.Location = New-Object System.Drawing.Point(360,100)
    $Reboot_Button.Size = New-Object System.Drawing.Size(120,40)
    $Reboot_Button.Text = "����Android�豸"
    $Reboot_Button.add_click( {Reboot} )

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
    $Time_label.Text = "���������ڣ�" + (Get-Date -Format "yyyy��M��d�� H:m:s")

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

    $Tab_adb_tools.Controls.Add($Show_android_version_Button)
    $Tab_adb_tools.Controls.Add($Info)
    $Tab_adb_tools.Controls.Add($Reboot_Button)

    $result = $MainForm.ShowDialog()
}

StartUp