#!/usr/bin/env python3
"""
Same closed-loop square driver as before, with one addition: it publishes
every pose it visits as a nav_msgs/Path on /square_path, and logs each
leg's start/end point. This lets you check the REAL shape in RViz (top-down,
Fixed Frame = odom) instead of judging it from a foreshortened 3D camera
view in Gazebo, which can make even a correctly-closed square look like an L.
"""
import math
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist, PoseStamped
from nav_msgs.msg import Odometry, Path


def yaw_from_quaternion(q):
    siny_cosp = 2 * (q.w * q.z + q.x * q.y)
    cosy_cosp = 1 - 2 * (q.y * q.y + q.z * q.z)
    return math.atan2(siny_cosp, cosy_cosp)


def normalise(angle):
    """Wrap any angle into [-pi, pi]."""
    return math.atan2(math.sin(angle), math.cos(angle))


class SquareDriver(Node):
    def __init__(self):
        super().__init__('square_driver')
        self.pub = self.create_publisher(Twist, '/cmd_vel', 10)
        self.sub = self.create_subscription(Odometry, '/odom', self.on_odom, 10)
        self.path_pub = self.create_publisher(Path, '/square_path', 10)
        self.timer = self.create_timer(0.05, self.control_loop)  # 20 Hz

        # ---- Path parameters ----
        self.side_length = 1.2
        self.turn_angle = math.pi / 2
        self.linear_speed = 0.3
        self.angular_speed = 0.4
        self.dist_tolerance = 0.03
        self.angle_tolerance = 0.03

        self.state = 'DRIVE'
        self.pose = None
        self.leg = 0

        self.leg_start_x = None
        self.leg_start_y = None
        self.target_yaw = None

        self.origin_x = None
        self.origin_y = None

        # ---- Path recording, for verifying the real shape afterward ----
        self.path_msg = Path()
        self.path_msg.header.frame_id = 'odom'
        self.last_logged_x = None
        self.last_logged_y = None

    def on_odom(self, msg):
        self.pose = msg.pose.pose

    def record_point(self, x, y, stamp):
        """Append the current pose to the Path and publish it, but only
        when the rover has actually moved a bit — keeps the path light."""
        if (self.last_logged_x is None
                or math.hypot(x - self.last_logged_x, y - self.last_logged_y) > 0.02):
            ps = PoseStamped()
            ps.header.frame_id = 'odom'
            ps.header.stamp = stamp
            ps.pose.position.x = x
            ps.pose.position.y = y
            self.path_msg.poses.append(ps)
            self.path_msg.header.stamp = stamp
            self.path_pub.publish(self.path_msg)
            self.last_logged_x, self.last_logged_y = x, y

    def control_loop(self):
        if self.pose is None:
            return

        x = self.pose.position.x
        y = self.pose.position.y
        yaw = yaw_from_quaternion(self.pose.orientation)
        stamp = self.get_clock().now().to_msg()

        self.record_point(x, y, stamp)

        if self.leg_start_x is None:
            self.leg_start_x, self.leg_start_y = x, y
            self.target_yaw = yaw
        if self.origin_x is None:
            self.origin_x, self.origin_y = x, y
            self.get_logger().info(f'Waypoint start: x={x:.3f} y={y:.3f}')

        if self.state == 'DONE':
            self.pub.publish(Twist())
            return

        twist = Twist()

        if self.state == 'DRIVE':
            distance = math.hypot(x - self.leg_start_x, y - self.leg_start_y)
            if distance < self.side_length - self.dist_tolerance:
                twist.linear.x = self.linear_speed
            else:
                self.pub.publish(Twist())
                self.get_logger().info(
                    f'Leg {self.leg}: drove {distance:.3f} m -> waypoint x={x:.3f} y={y:.3f}. Turning.'
                )
                self.state = 'TURN'
                self.target_yaw = normalise(yaw + self.turn_angle)
                return

        elif self.state == 'TURN':
            error = normalise(self.target_yaw - yaw)
            if abs(error) > self.angle_tolerance:
                twist.angular.z = math.copysign(self.angular_speed, error)
            else:
                self.pub.publish(Twist())
                self.leg += 1
                self.get_logger().info(f'Leg {self.leg}: turn complete, residual error {error:.3f} rad.')
                if self.leg >= 4:
                    self.state = 'DONE'
                    dx, dy = x - self.origin_x, y - self.origin_y
                    self.get_logger().info(
                        f'Square complete. Final position error from start: '
                        f'dx={dx:.3f} m, dy={dy:.3f} m, |error|={math.hypot(dx, dy):.3f} m'
                    )
                    self.get_logger().info(
                        f'Recorded {len(self.path_msg.poses)} path points on /square_path '
                        f'(view in RViz: Fixed Frame=odom, Add -> Path -> topic /square_path)'
                    )
                else:
                    self.state = 'DRIVE'
                    self.leg_start_x, self.leg_start_y = x, y
                return

        self.pub.publish(twist)


def main(args=None):
    rclpy.init(args=args)
    node = SquareDriver()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.pub.publish(Twist())
        node.destroy_node()
        rclpy.shutdown()


if __name__ == '__main__':
    main()
