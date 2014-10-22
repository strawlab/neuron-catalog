from __future__ import print_function
from singleton_config import run_config_program

def main():
    run_config_program(desc="get or set neuron catalog administrative configuration",
                       collection_name="admin_config")
    
if __name__=='__main__':
    main()
