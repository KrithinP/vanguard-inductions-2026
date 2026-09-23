import rclpy
from rclpy.node import Node 
from geometry_msgs.msg import Twist

class TurtleNode(Node):
   def __init__(self):
      super().__init__('turtle_controller')
      self.publisher_ = self.create_publisher(Twist, '/turtle1/cmd_vel', 10)
      self.timer = self.create_timer(0.1, self.publish_velocity)


   def publish_velocity(self):
      msg = Twist()

      msg.linear.x = 2.0
      msg.linear.y = 0.0
      msg.linear.z = 0.0

      msg.angular.x = 0.0
      msg.angular.y = 0.0
      msg.angular.z = 2.0

      self.publisher_.publish(msg)

def main(args=None):
    rclpy.init(args=args)
    node = TurtleNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
     main() 
