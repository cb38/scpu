# simple CPU implented in sky130 
  
This is to run with librelane to generate full GDS implementation in sky130  

librelane can be found [here](https://librelane.readthedocs.io/en/latest/getting_started/)
please follow the installation

After installation open a terminal in the librelane folder
and run nix : 
```sh
nix 
```
navigate to this folder and run 
```sh
librelane config.json
```

If no error you can open gds with 
```sh
librelane --last-run --flow klayout config.json 
```