#!/usr/bin/env python3

import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist
from nav_msgs.msg import Odometry
import math

class SquareDriver(Node):
    def __init__(self):
        super().__init__('square_driver')
        self.pub = self.create_publisher(Twist, '/cmd_vel', 10)
        self.sub = self.create_subscription(Odometry, '/odom', self.on_odom, 10)
        self.timer = self.create_timer(0.05, self.control_loop)   # 20 Hz

        self.state = 'DRIVE'        # DRIVE -> TURN -> DRIVE -> ... -> DONE
        self.pose = None
        self.leg = 0
        
        # State tracking coordinates
        self.start_x = None
        self.start_y = None
        self.start_yaw = None

        # Fixed configuration constraints
        self.target_distance = 2.0
        self.target_turn = math.pi / 2.0  # 90 degrees in radians
        
        self.linear_speed = 0.2
        self.angular_speed = 0.3
        
        self.get_logger().info('SquareDriver node initialized. Waiting for /odom data...')

    def on_odom(self, msg):
        self.pose = msg.pose.pose         # just store it

    def get_yaw_from_pose(self):
        """Helper to extract Euler yaw directly from the active self.pose quaternion."""
        q = self.pose.orientation
        siny_cosp = 2.0 * (q.w * q.z + q.x * q.y)
        cosy_cosp = 1.0 - 2.0 * (q.y * q.y + q.z * q.z)
        return math.atan2(siny_cosp, cosy_cosp)

    def normalize_angle(self, angle):
        """Wraps angle differences cleanly between -PI and +PI."""
        while angle > math.pi: angle -= 2.0 * math.pi
        while angle < -math.pi: angle += 2.0 * math.pi
        return angle

    def control_loop(self):
        if self.pose is None:
            return     

        twist = Twist()
        current_yaw = self.get_yaw_from_pose()

        if self.state == 'DRIVE':
            # Record where this specific straight leg segment started
            if self.start_x is None:
                self.start_x = self.pose.position.x
                self.start_y = self.pose.position.y
                self.get_logger().info(f'Leg {self.leg + 1}: Moving 2 meters forward...')

            # Calculate Euclidean distance relative to the stored reference
            distance_moved = math.sqrt((self.pose.position.x - self.start_x)**2 + 
                                       (self.pose.position.y - self.start_y)**2)

            if distance_moved < self.target_distance:
                twist.linear.x = self.linear_speed
            else:
                # Target reached; stop the rover and pivot state variables
                twist.linear.x = 0.0
                self.pub.publish(twist)
                self.start_x = None
                self.start_y = None
                self.state = 'TURN'

        elif self.state == 'TURN':
            # Record the initial heading baseline when this rotation begins
            if self.start_yaw is None:
                self.start_yaw = current_yaw
                self.get_logger().info(f'Leg {self.leg + 1}: Rotating 90 degrees...')

            # Determine absolute displacement from start point
            angle_turned = abs(self.normalize_angle(current_yaw - self.start_yaw))

            if angle_turned < self.target_turn:
                twist.angular.z = self.angular_speed
            else:
                # Pivot completed; stop rotation and increment leg loop counter
                twist.angular.z = 0.0
                self.pub.publish(twist)
                self.start_yaw = None
                self.leg += 1

                # If 4 legs are completed, stop entirely
                if self.leg >= 4:
                    self.state = 'DONE'
                    self.get_logger().info('Square trajectory completed!')
                else:
                    self.state = 'DRIVE'

        elif self.state == 'DONE':
            twist.linear.x = 0.0
            twist.angular.z = 0.0
            self.timer.destroy() # Disables further callbacks from firing

        self.pub.publish(twist)

def main(args=None):
    rclpy.init(args=args)
    node = SquareDriver()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
