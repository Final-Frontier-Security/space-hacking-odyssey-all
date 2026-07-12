# Blackboard - NOS3 Component
This repository contains the NOS3 Blackboard Component.
This includes simulation directory.

## Component Template
This component template utilizes canned files from the existing [blackboard component](https://github.com/nasa-itc/blackboard) to generate a new component to do development in.

Expected utilization:  
* Determine the desired component name
* Create a new submodule for the component via GitHub
* Add the submodule to this project
  * `git submodule init`
  * `git submodule add -f -b main <New_Submodule_Link> ./components/<New_Component_Name>`
* Generate the new files
  * `./generate_template.sh <New_Component_Name>`
    * Note that <New_Component_Name> must be <= 10 characters by default or you'll need to shorten the software bus pipe name after the fact
* The new files should be placed in the submodule
  * `../<New_Component_Name>/`
* Commit the new files to the submodule
  * `git add * && git add .gitignore`
  * `git commit -m "Initial component template based on version 0.0.0"`
* Add new component to flight software (fsw) in the following files:
  * `./fsw/nos3_defs/cpu1_cfe_es_startup.scr`
  * `./fsw/nos3_defs/targets.cmake`
  * `./fsw/nos3_defs/tables/*`
* Add new component to ground software (gsw) in the following files:
  * `./gsw/cosmos/config/system/nos3_system.txt`
  * `./gsw/cosmos/config/tools/cmd_tlm_server/nos3_cmd_tlm_server.txt`
  * `./gsw/scripts/launch.sh`

## Overview
This component provides a NOS3 simulation which populates a shared memory blackboard with data from 42.


# Configuration
The various configuration parameters available for each portion of the component are captured below.

## FSW
Refer to the file [fsw/platform_inc/blackboard_platform_cfg.h](fsw/platform_inc/blackboard_platform_cfg.h) for the default
configuration settings, as well as a summary on overriding parameters in mission-specific repositories.

## Simulation
```
<simulator>
    <name>blackboard_sim</name>
    <active>true</active>
    <library>libblackboard_sim.so</library>
    <hardware-model>
        <type>BLACKBOARD</type>
        <connections>
            <connection><type>command</type>
                <bus-name>command</bus-name>
                <node-name>blackboard-sim-command-node</node-name>
            </connection>
            <connection><type>shmem</type>
                <bus-name>nos3_shmem</bus-name>
                <node-port>nos3_mutex</node-port>
            </connection>
        </connections>
        <data-provider>
            <type>BLACKBOARD_PROVIDER</type>
        </data-provider>
    </hardware-model>
</simulator>
```

## 42
Optionally the 42 data provider can be configured in the `nos3-simulator.xml`:
```
        <data-provider>
            <type>BLACKBOARD_42_PROVIDER</type>
            <hostname>localhost</hostname>
            <port>4242</port>
            <max-connection-attempts>5</max-connection-attempts>
            <retry-wait-seconds>5</retry-wait-seconds>
            <spacecraft>0</spacecraft>
        </data-provider>
```


# Documentation
If this blackboard application had an ICD and/or test procedure, they would be linked here.

## Releases
We use [SemVer](http://semver.org/) for versioning. For the versions available, see the tags on this repository.
* v1.0.0 - X/Y/Z 
  - Updated to be a component repository including FSW, GSW, Sim, and Standalone checkout
* v0.1.0 - 10/9/2021 
  - Initial release with version tagging
