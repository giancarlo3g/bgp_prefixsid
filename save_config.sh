#!/bin/bash

# List of files to check
if [ ! -d ./config ]; then
  mkdir -p ./config
fi

# SROS devices
yes | cp ./clab-bgpprefixsid/R01-IXR/A/config/cf3/config.cfg ./config/R01-IXR.cfg
yes | cp ./clab-bgpprefixsid/R02-IXR/A/config/cf3/config.cfg ./config/R02-IXR.cfg
yes | cp ./clab-bgpprefixsid/R03-IXR/A/config/cf3/config.cfg ./config/R03-IXR.cfg
yes | cp ./clab-bgpprefixsid/R04-IXR/A/config/cf3/config.cfg ./config/R04-IXR.cfg
yes | cp ./clab-bgpprefixsid/R05-SR/A/config/cf3/config.cfg ./config/R05-SR.cfg
yes | cp ./clab-bgpprefixsid/R06-SR/A/config/cf3/config.cfg ./config/R06-SR.cfg
yes | cp ./clab-bgpprefixsid/R07-SR/A/config/cf3/config.cfg ./config/R07-SR.cfg
yes | cp ./clab-bgpprefixsid/R08-SR/A/config/cf3/config.cfg ./config/R08-SR.cfg
yes | cp ./clab-bgpprefixsid/R09-SR/A/config/cf3/config.cfg ./config/R09-SR.cfg
yes | cp ./clab-bgpprefixsid/R10-SR/A/config/cf3/config.cfg ./config/R10-SR.cfg
yes | cp ./clab-bgpprefixsid/R11-SR/A/config/cf3/config.cfg ./config/R11-SR.cfg
no  | cp ./clab-bgpprefixsid/R12-SR/A/config/cf3/config.cfg ./config/R12-SR.cfg
yes | cp ./clab-bgpprefixsid/R13-IXR/A/config/cf3/config.cfg ./config/R13-IXR.cfg
yes | cp ./clab-bgpprefixsid/R14-IXR/A/config/cf3/config.cfg ./config/R14-IXR.cfg
yes | cp ./clab-bgpprefixsid/R15-IXR/A/config/cf3/config.cfg ./config/R15-IXR.cfg
yes | cp ./clab-bgpprefixsid/R16-IXR/A/config/cf3/config.cfg ./config/R16-IXR.cfg

# SRL devices
yes | cp ./clab-bgpprefixsid/R12-SXR/config/config.json ./config/R12-SXR.json
yes | scp R12-SXR:/home/admin/config.cfg ./config/R12-SXR.cfg

