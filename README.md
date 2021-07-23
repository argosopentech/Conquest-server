# CONQUEST DEDICATED SERVER

### <b>EXPORTING SERVER</b>

Conquest is an online open source strategy game, very similar to RISK.

You can find the game's source code here: https://github.com/argosopentech/Conquest

This read-me describes how we can set up its dedicated server.

For that you will need both, the client side source code and the server side source code.

You can grab the server side code here in this repository.

After that you have to choose a platform you want to run your game’s server on, mostly Linux is best suited for this task and we will will be using it below.

For Linux, you have to export the server project’s pck file only but as Linux preset set.

I have saved it as ```ConquestServer.pck```

![Linux Preset](/images/LinuxExport.PNG)

### <b>GODOT SERVER</b>

Now we have to grab Godot’s server binary for linux: https://godotengine.org/download/server

![Server Binary](/images/GodotServerDownload.PNG)

You can also compile it yourself from Godot’s source code, for more information on that: 

https://docs.godotengine.org/en/stable/development/compiling/compiling_for_x11.html

Once you have the zip file, you can extract it and copy it in the same folder as your server pck file.

After that, you can rename the server file the same as your pck file, excluding the extension.

Now that we have both files, we are ready to put the server into production.

### <b>LINODE</b>

I will be using Ubuntu 20.04 on Linode to run my server.

You can use any other Linux distro and even follow along if you have Linux in your local computer.

For that we will go to: https://cloud.linode.com/linodes and you might have to sign up for an account if you are a new user, after that you should see a similar screen.

![Linode Home](/images/LinodeHome.PNG)

You can hit the Create Linode button, and it will bring you to the setup screen.

### <b>LINODE SETUP</b>

I have chosen Ubuntu 20.04 LTS as my distribution image.

I have chosen Atlanta, GA as the region and Nanode 1 GB as my Linode plan.

![Linode Plan](/images/LinodeSetup.PNG)

You can also set the Linode label, add any tags and set your root password.

Finally you can also choose backup plans and a private ip.

Once you have set up everything hit the Create Linode button in the right sidebar of the screen.

It should take a few minutes while it prepares your Linode machine.

After that, it should provide you the IP addresses and SSH Access.

Note the IP address, we will use it to connect to our server in the next section.

### <b>SERVER LOGIN</b>

Now that we have the server setup, we can login to it and put our Godot files in there.

If you are on Linux, you can access the server just by using your terminal but if you are on Windows, you will use something called Putty to access your server.

We will use Putty in this wiki, to get it simple goto this link: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

After downloading it, you just double click and Install the software.

Once finished installing, you can access it via Start Menu, it should look like this:

![Putty](/images/Putty.PNG)

You can type in your IP address here that you got from Linode and hit the Open button, which should bring a console window, where you can login as root and password that you set up when creating your Linode.

### <b>SERVER UPDATE</b>

This console window is basically your server’s terminal, so whenever you want to do anything to the server you do it here.

![Putty Login](/images/PuttyConsole.PNG)

After you first login, it's generally a good idea to update a Linux machine.

Simply type in:

```
apt-get update && apt-get upgrade
```

Type in y+enter if it asks for your permissions during the update.

Once finished, we can move on to copying our files to the server.

### <b>FTP CLIENT</b>

To transfer files to the server, we need a FTP client program like FileZilla:

https://filezilla-project.org/download.php?type=client

Once you download it, simply install it by hitting the next buttons.

It should look something like this when you open it after installation:

![FileZilla](/images/FileZilla.PNG)


You can put your IP in the Host column, root as your username and password as password.

For the port we will be using port 22, so simply put 22 in there and hit the Quickconnect button.

### <b>FILE TRANSFER</b>

File browser on the left is for your local computer, and the right one is representing your server.

Simply browse to the exports folder in your local computer and browse to the home folder in your server.

You can then create a conquest_server folder in the server side, path should be /home/conquest_server/

After that you can drag the files from your local computer into the server by simply dragging them across.

![FileZilla File Transfer](/images/FileZilla-FileTransfer.PNG)

### <b>FILE PERMISSIONS</b>

In linux, you can't execute a program if you don’t have proper file permissions set for it.


To do that, we have to select our server files in the server side, right click and select File permissions… option (usually the bottom one)

After that it should open a File Permission menu, simply check all the checkboxes and hit the OK button.

![FileZilla File Permissions](/images/FileZilla-FilePermissions.PNG)

### <b>RUNNING THE SERVER</b>

After transferring our files and setting permissions to them, we are now ready to run our server.


To do that, we have to head back to our Putty console and login again.

After that, simply change the directory to ```/home/conquest_server/```

Or simply write this command:

```
cd /home/conquest_server/
```

Once there, you can type in:

```
./ConquestServer.64
```

And it should run our server.

![Running the server](/images/Putty-GodotServerRunning.PNG)

### <b>RUNNING THE CLIENT</b>

Once we have server side ready and running, we can head over to the client side and replace our previous local IP to our new Ubuntu server IP.

Head over to ```res://Source/Server/Server.gd```

In there, change the SERVER_IP constant to your server's IP and make sure to keep it in the double quotes.

![Changing Server IP](/images/ConquestClientServerFile.PNG)

After that, you can export the game and play it with your friends and community powered by your own dedicated server.

### <b>BONUS</b>

Right now our server works and everything seems fine, until we restart the ubuntu server or if there is any crash, then our server just stops there and does not continue to run.

To get around that, we create Linux services that run in the background and restart when there is any crash or simply when the main server reboots.

Basically we have to create a systemd service for our conquest_server and set it to restart when necessary.

To do that, simply hit ```CTRL + C``` to close our godot server and type in this command:

```
nano /etc/systemd/system/conquest_server.service
```

This should create and open the conquest_server.service file in the nano editor.

Then copy and paste this code in the file:

```
[Unit]
Description=Conquest Server service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/home/conquest_server/ConquestServer.64

[Install]
WantedBy=multi-user.target
```

Then hit ```CTRL + O``` then ```ENTER``` and then ```CTRL + X``` to exit the editor

Now to start the service, enter this command:

```
systemctl start conquest_server.service
```

And to enable it, simply enter:

```
systemctl enable conquest_server.service
```

Now our server should be all good :)
