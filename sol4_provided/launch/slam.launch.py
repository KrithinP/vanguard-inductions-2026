"""Online asynchronous SLAM for the Vanguard rover.

Provided. Run it, drive around, and watch a map appear:

    ros2 launch sol4_provided slam.launch.py

Then save the map:

    ros2 run nav2_map_server map_saver_cli -f ~/vanguard_ws/arena_map
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node


def generate_launch_description():
    params = os.path.join(
        get_package_share_directory('sol4_provided'), 'config', 'slam_toolbox.yaml')

    use_sim_time = LaunchConfiguration('use_sim_time')

    return LaunchDescription([
        DeclareLaunchArgument(
            'use_sim_time', default_value='true',
            description='Use simulated /clock. Keep this true when running Gazebo.'),

        Node(
            package='slam_toolbox',
            executable='async_slam_toolbox_node',
            name='slam_toolbox',
            output='screen',
            parameters=[params, {'use_sim_time': use_sim_time}],
        ),

        # slam_toolbox is a LIFECYCLE node: it boots into 'unconfigured', where it
        # subscribes to nothing and logs nothing. Without this manager it looks
        # like it started fine and simply never produces a map.
        # (We lost an afternoon to exactly that while building this.)
        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_slam',
            output='screen',
            parameters=[{
                'use_sim_time': use_sim_time,
                'autostart': True,
                'node_names': ['slam_toolbox'],
            }],
        ),
    ])
