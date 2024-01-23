# YANG

## Generate Python class hierarchy

1. Generate Python class structure

```bash
export PYBINDPLUGIN=`python3 -c 'import pyangbind; import os; print ("{}/plugin".format(os.path.dirname(pyangbind.__file__)))’`
```

```bash
pyang -f pybind topology.yang --plugindir $PYBINDPLUGIN o bind_topology.py
```

## Communication

1. Generate protobuf from YANG

```bash
protogenerator --output_dir=. --package_name=topology topology.yang 
```
