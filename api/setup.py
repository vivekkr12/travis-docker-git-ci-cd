import setuptools

import api

with open('requirements.txt', 'r') as req:
    requirements = req.readlines()


PACKAGE_NAME = 'api'
VERSION = api.__version__

setuptools.setup(
    name=PACKAGE_NAME,
    version=VERSION,
    intall_package_data=True,
    description='Test Package',
    long_description='',
    long_description_content_type='text/markdown',
    packages=setuptools.find_packages(exclude=["*.test", "*.test.*", "test.*", "test"]),
    install_requires=requirements,
    classifiers=[
        'Programming Language :: Python :: 3',
        'Operating System :: OS Independent',
    ]
)
