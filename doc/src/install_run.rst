====================
Building Mesh Editor
====================
Follow the instructions below to build the Mesh Editor and to run it.

Step 1: Install the Flex SDK:
-----------------------------
To build the Mesh Editor first you will need to install the Flex SDK
::
    \$ mkdir flex_sdk
    \$ cd flex_sdk
    \$ wget http://hpfem.org/downloads/flex_sdk_3.5.zip
    \$ unzip flex_sdk_3.5.zip

To add flex_sdk.3.5/bin directory to your system path:
change the following script according to your need and to your bashrc
::
    \$ export PATH=\$PATH:path_to/flex_sdk.3.5/bin

This PATH export is a temporary solution (valid only in your
current terminal session). To make it permanent, you need to
add the following line into your .bashrc file
::
    \$ export PATH=\$PATH:/home/pavel/tmp/flex_sdk/bin

Adapt the path to the one you chose for your installation.

Step 2: Clone the Mesh Editor Git Repository
--------------------------------------------
Now clone the mesh editor git repository (if you have not already done so)
::
    \$ git clone git://github.com/hpfem/mesheditor-flex.git

Step 3: Compile the mesh editor
--------------------------------
To compile the mesh editor type
::
    \$ cd mesheditor-flex
    \$ make

This will compile and create a binary file MeshEditor.swf in the directory, which can be opened directly using a browser or can be installed in the FEMhub Online Lab as described in the step 3 below.

Step 3: Install mesh editor in FEMhub
-------------------------------------
If you want to install the mesh editor in FEMhub
::
     \$ make install
This will compile & install mesh editor in your local femhub

Test the Mesh Editor
--------------------
To test mesh editor:

After compilation ``MeshEditor.swf`` file will be generated.

Then open it in a browser
::
   \$ firefox MeshEditor.swf

This way you can test some of the mesh editing features but
triangulation feature will not work.

To use its full features, run local FEMhub, run the online lab and launch the
mesh editor.
