# Mission log

---

## Sol 1 — Boot Sequence

**Route taken:** Docker Desktop on Windows ,though I have pre installed ubuntu ,it's 22 version (installed with ros 2humble) , hence I decided to work in docker for ros2 jazzy and leave the dual boot as it is
**Time spent:** ~_6_ hours

1)   ros2 run turtlesim turtlesim_node :
	this command did not run in my docker (in terminal root@02xxx1efb7)
	error occurs because the turtlesim node relies on a graphical window (Qt/XCB), but your Docker container does not have permission to connect to your host machine's display screen
Hence installed Xlaunch and typed the below command
export DISPLAY=host.docker.internal:0.0
2)I mistakenly did Colcon build inside src , found the mistake then went back to parent directory vangaurd_ws
and used echo command
3)I did n't run tutlesim node, instead only ran publisher node first_light/circle , so ran first turtle sim node and then ran ros2 run first_light circle(in the terminal where source and colcon build is typed already), my square python file had errors turtle wasn't drawing perfect square hence submitted circle node



---

## Sol 2 — Rolling Chassis

**Time spent:** ~_8/10_ hours

**What I got working**
    
**Final position error after the square:** ___ m — *and why I think it's that much*
    error in positon might be beacuse of the angle conversion which is in radians maynot be perfect and also the slippery of wheel

**What broke, and how I worked it out**
    ERROR1:-
root@0e1bac42f6b7:~/vanguard_ws# colcon build --symlink-install
[4.270s] ERROR:colcon:colcon build: Duplicate package names not supported:
- first_light:
  - src/first_light
  - src/sol1/first_light
root@0e1bac42f6b7:~/vanguard_ws#
the new error above i found after typing colcon command ,and realised from internet that ROS 2 cannot have two packages with the exact same name in the active build graph, colcon stops immediately.
(I had First_light copied file in Sol1 also under src)

ERROR 2:-
root@0e1bac42f6b7:~/vanguard_ws# ros2 launch first_light display.launch.py
[INFO] [launch]: All log files can be found below /root/.ros/log/2026-09-24-14-40-20-438038-0e1bac42f6b7-1133
[INFO] [launch]: Default logging verbosity is set to INFO
[ERROR] [launch]: Caught exception in launch (see debug for traceback): "package 'joint_state_publisher_gui' not found, searching: ['/root/vanguard_ws/install/vanguard_navigation', '/root/vanguard_ws/install/first_light', '/opt/ros/jazzy']"
The error shows that ROS 2 Jazzy cannot find the package joint_state_publisher_gui, HENCE DOWNLOADED THE PKG via sudo sudo apt update && sudo apt install -y ros-jazzy-joint-state-publisher-gui

    ERROR 3:-root@0e1bac42f6b7:~/vanguard_ws# cd ~/vanguard_ws
colcon build --symlink-install
source install/setup.bash
Starting >>> first_light
Starting >>> vanguard_navigation
Starting >>> vanguard_rover
Finished <<< vanguard_navigation [28.1s]
Finished <<< first_light [29.7s]
 stderr: vanguard_rover
error: can't copy '/root/vanguard_ws/build/vanguard_rover/package.xml': doesn't exist or not a regular file
Failed   <<< vanguard_rover [29.6s, exited with code 1]
Summary: 2 packages finished [36.7s]
  1 package failed: vanguard_rover
  1 package had stderr output: vanguard_rover
root@0e1bac42f6b7:~/vanguard_ws# ,
MY package XML was someother directory hence thought of relocating it

    ERROR4:- Did not type this command beforehand" chmod +x ~/vanguard_ws/src/vanguard_rover/vanguard_rover/square_drive.py", created under init.py
---

## Sol 3 — Eyes

**Time spent:** ~__ hours

**Measured vs estimated marker distance:** true ___ m, estimated ___ m

**What broke, and how I worked it out**

---

## Sol 4 — Terra Incognita *(bonus)*

**Time spent:** ~__ hours
**How far I got:** avoidance / action client / explorer

**What broke, and how I worked it out**

---

## Anomaly report

Anything that fought you and isn't covered above. Environment problems, a wrong
turn you spent a day on, a thing in our instructions that was unclear or plain
wrong. **Telling us our handbook is wrong is a good look, not a bad one.**

## Tools I used

AI assistants, tutorials, forum answers, a friend. All fine — just say so. The
only rule is that you understand every line you submitted.
