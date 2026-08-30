"""Nav2 for the Vanguard rover.

Provided. Assumes SLAM (or a map server) is already publishing map -> odom.

    ros2 launch vanguard_navigation nav2.launch.py

Then in RViz use the "2D Goal Pose" button to send it somewhere.
"""
import os

from ament_index_python.packages import get_package_share_directory
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node

LIFECYCLE_NODES = [
    'controller_server',
    'planner_server',
    'behavior_server',
    'bt_navigator',
    'velocity_smoother',
]

def generate_launch_description():
    params = os.path.join(
        get_package_share_directory('vanguard_navigation'), 'config', 'nav2_params.yaml')

    use_sim_time = LaunchConfiguration('use_sim_time')
    common = [params, {'use_sim_time': use_sim_time}]

    return LaunchDescription([
        DeclareLaunchArgument('use_sim_time', default_value='true'),

        Node(package='nav2_controller', executable='controller_server',
             output='screen', parameters=common),
        Node(package='nav2_planner', executable='planner_server',
             output='screen', parameters=common),
        Node(package='nav2_behaviors', executable='behavior_server',
             output='screen', parameters=common),
        Node(package='nav2_bt_navigator', executable='bt_navigator',
             output='screen', parameters=common),
        Node(package='nav2_velocity_smoother', executable='velocity_smoother',
             output='screen', parameters=common),

        # Nav2 nodes are LIFECYCLE nodes: they start inactive and must be
        # configured and activated. The lifecycle manager does that for you.
        # If navigation does nothing at all, check this node's log first —
        # a server that failed to activate is the usual cause.
        Node(
            package='nav2_lifecycle_manager',
            executable='lifecycle_manager',
            name='lifecycle_manager_navigation',
            output='screen',
            parameters=[{
                'use_sim_time': use_sim_time,
                'autostart': True,
                'node_names': LIFECYCLE_NODES,
            }],
        ),
    ])
