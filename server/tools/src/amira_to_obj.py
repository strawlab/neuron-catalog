#!/usr/bin/env python
import sys
from read_amira_surf import read_surf

def str_from_vec(vec):
    return ' '.join([ repr(vi) for vi in vec ])

def write_verts(fd, arr, key):
    for row in arr:
        fd.write( key + ' '+ str_from_vec(row) + '\n' )

def amira_to_obj(input_filename, output_filename):
    with open(input_filename,mode='rb') as fileobj:
        surf = read_surf( fileobj )
    with open(output_filename,mode='wb') as fd:
        for row in surf:
            if row.has_key('Vertices'):
                write_verts(fd, row['Vertices'],'v')
            if row.has_key('Triangles'):
                write_verts(fd, row['Triangles'],'f')

if __name__=='__main__':
    input_filename = sys.argv[1]
    obj_filename = input_filename + '.obj'
    amira_to_obj(input_filename, obj_filename)
