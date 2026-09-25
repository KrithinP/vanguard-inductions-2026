import math
import rclpy
from rclpy.node import Node
from geometry_msgs.msg import Twist

class SquarePublisher(Node):
    def __init__(self):
        super().__init__('square_publisher')
        self.publisher_ = self.create_publisher(Twist, '/turtle1/cmd_vel', 10)
        self.timer = self.create_timer(0.1, self.timer_callback)  # 10 Hz
        self.state = 'FORWARD'
        self.ticks = 0

    def timer_callback(self):
        msg = Twist()
        self.ticks += 1

        if self.state == 'FORWARD':
            msg.linear.x = 2.0
            msg.angular.z = 0.0
            # Drive forward for 2 seconds (20 ticks at 10 Hz)
            if self.ticks >= 20:
                self.state = 'TURN'
                self.ticks = 0

        elif self.state == 'TURN':
            msg.linear.x = 0.0
            msg.angular.z = math.pi / 2  # 90 degrees/sec
            # Rotate 90 deg for 1 second (10 ticks at 10 Hz)
            if self.ticks >= 10:
                self.state = 'FORWARD'
                self.ticks = 0

        self.publisher_.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = SquarePublisher()
    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
