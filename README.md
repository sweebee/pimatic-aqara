pimatic-aqara
=======================

For controlling and receiving events from the Aqara (Xiaomi) Gateway.

#### Supported devices

- Aqara Human Motion Sensor 
- Aqara Wireless Single Switch (On / Off)
- Aqara Window Door Sensor
- Aqara Smart Wireless Switch (click / longpress / doublepress)
- Aqara Water/Leak Sensor (dry / wet)
- Aqara Temperature/Humidity/Pressure sensor

##### Not (yet) supported
 - Aqara Smart Lock
 - Aqara Curtain motor
 - Aqara magic cube
 
*( Feel free to donate one ;) )*

#### Setup
The Gateway must be in developer mode, when setting to developer mode you will also receive an password, save it because you need it to add the plugin.

Just install the plugin from the plugin page within pimatic, enable it and enter the password you received from the gateway by setting it in developer mode.

To add devices, just go to the devices page in pimatic and press "discover devices", the devices connected to the gateway should popup.

 
#### Enabling developer mode
 
- Select your Gateway in the MiHome app
- Go to the “…” menu on the top right corner and click “About”
- Tap the version number “Version : 2.XX” at the bottom of the screen repeatedly until you enable developer mode
- You should now have 2 extra options listed: local area network communication protocol and gateway information
- Choose local area network communication protocol
- Tap the toggle switch to enable LAN functions. Note down the developer key (something like: 91bg8zfkf9vd6uw7)
- Make sure you hit the OK button (to the right of the cancel button) to save your changes

Original documention from:
https://docs.openhab.org/addons/bindings/mihome/readme.html#setup