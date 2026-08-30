import os
from glob import glob

from setuptools import setup

package_name = 'vanguard_navigation'

setup(
    name=package_name,
    version='1.0.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
        (os.path.join('share', package_name, 'launch'), glob('launch/*.py')),
        (os.path.join('share', package_name, 'config'), glob('config/*.yaml')),
    ],
    install_requires=['setuptools'],
    zip_safe=True,
    maintainer='Project Vanguard',
    maintainer_email='noreply@example.com',
    description='Provided SLAM and Nav2 configuration for the bonus mission.',
    license='MIT',
    entry_points={'console_scripts': []},
)
