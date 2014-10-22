from __future__ import print_function
from singleton_config import run_config_program

def main():
    run_config_program(desc="get or set neuron catalog configuration",
                       collection_name="neuron_catalog_config")
    
if __name__=='__main__':
    main()
