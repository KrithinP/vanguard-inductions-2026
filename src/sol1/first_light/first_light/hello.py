import rclpy                        # the ROS 2 Python library
from rclpy.node import Node         # base class for every node
from std_msgs.msg import String     # the message type we'll send

class HelloPublisher(Node):
    def __init__(self):
        super().__init__('hello_publisher')     # this node's name on the graph

        # Create a publisher: (message type, topic name, queue depth)
        self.publisher_ = self.create_publisher(String, 'greeting', 10)

        # Call self.tick() every 0.5 s — that's 2 Hz
        self.timer = self.create_timer(0.5, self.tick)
        self.count = 0

        self.get_logger().info('Hello publisher started')

    def tick(self):
        msg = String()
        msg.data = f'hello from the rover, message {self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1

def main(args=None):
    rclpy.init(args=args)           # start up ROS
    node = HelloPublisher()
    try:
        rclpy.spin(node)            # hand control to ROS; run callbacks forever
    except KeyboardInterrupt:
        pass
    finally:
        node.destroy_node()
        rclpy.shutdown()

if __name__ == '__main__':
    main()
