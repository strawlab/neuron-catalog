#!/usr/bin/env python
import sys
import os
import re
import numpy as np
from StringIO import StringIO

TOKEN_NAME = 'name'
TOKEN_NUMBER = 'number'
TOKEN_STRING = 'string'
TOKEN_OP = 'op'
TOKEN_COMMENT = 'comment'
TOKEN_NEWLINE = 'newline'
TOKEN_COMMA = 'comma'
TOKEN_Vec3Array = 'Vec3Array'
TOKEN_ENDMARKER = 'endmarker'

dtypes = {'Vertices':np.float32,
          'Triangles':np.int32,
      }
ARRAY_FIELDS = dtypes.keys()

def get_nth_index( buf, seq, n ):
    """find the index of the nth occurance of seq in buf"""
    assert n>=1
    cur_base = 0
    cur_buf = buf
    for i in range(n):
        this_idx = cur_buf.index(seq)
        idx = cur_base + this_idx
        cur_base += this_idx+len(seq)
        cur_buf = cur_buf[this_idx+len(seq):]
    return idx

def test_get_nth_index_simple():
    buf = 'abcbdb'
    assert buf.index( 'b' )==1
    assert get_nth_index( buf, 'b', 1 )==1
    assert get_nth_index( buf, 'b', 2 )==3
    assert get_nth_index( buf, 'b', 3 )==5

def test_get_nth_index_complex():
    buf = 'aa111bb111cc111'
    assert buf.index( '111' )==2
    assert get_nth_index( buf, '111', 1 )==2
    assert get_nth_index( buf, '111', 2 )==7
    assert get_nth_index( buf, '111', 3 )==12

class Matcher:
    def __init__(self,rexp):
        self.rexp = rexp
    def __call__(self, buf ):
        matchobj = self.rexp.match( buf )
        return matchobj is not None

re_string_literal = re.compile(r'^"(.*)"$')
is_string_literal = Matcher(re_string_literal)

# from http://stackoverflow.com/a/12929311/1633026
re_float = re.compile(r'^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?$')
is_number = Matcher(re_float)

re_name = re.compile(r'^[a-zA-Z0-9]+$')
is_name = Matcher(re_name)

class Tokenizer:
    def __init__( self, fileobj ):
        self.buf = fileobj.read()
        self.last_tokens = []
        self.is_binary = False
    def get_tokens( self ):
        # keep a running accumulation of last 2 tokens
        for token_enum,token in enumerate(self._get_tokens()):
            self.last_tokens.append( token )
            while len(self.last_tokens) > 3:
                self.last_tokens.pop(0)
            if token_enum==0:
                if token[0] == TOKEN_COMMENT and token[1]=='# HyperSurface 0.1 BINARY':
                    self.is_binary = True
                elif token[0] == TOKEN_COMMENT and token[1]=='# HyperSurface 0.1 ASCII':
                    self.is_binary = False
                else:
                    warnings.warn('Unknown HyperSurface file type. Parsing may fail.')
            yield token
    def _get_tokens( self ):
        newline = '\n'
        lineno = 0
        while len(self.buf) > 0:

            if (len(self.last_tokens)>=3 and
                self.last_tokens[-3][0]==TOKEN_NAME and
                self.last_tokens[-3][1] in ARRAY_FIELDS and
                self.last_tokens[-2][0]==TOKEN_NUMBER and
                self.last_tokens[-1][0]==TOKEN_NEWLINE):

                n_elements = int(self.last_tokens[-2][1])

                if self.is_binary:
                    sizeof_element = 3*4 # 3x floats, 4 bytes per float
                    n_bytes = n_elements * sizeof_element

                    this_line, self.buf = self.buf[:n_bytes], self.buf[n_bytes:]
                    lineno += 1

                    assert len(this_line)==n_bytes

                    this_data = parse_binary_data(this_line,dtypes[self.last_tokens[-3][1]])
                    yield ( TOKEN_Vec3Array, this_data, (lineno,0), (lineno, n_bytes), this_line )
                else:
                    idx = get_nth_index( self.buf, newline, n_elements )
                    this_line, self.buf = self.buf[:idx], self.buf[idx:]
                    lineno += n_elements

                    this_data = parse_ascii_data(this_line)
                    yield ( TOKEN_Vec3Array, this_data, (lineno-n_elements,0), (lineno, None), this_line )
                continue

            # get the next line -------
            idx = self.buf.index(newline)+1
            this_line, self.buf = self.buf[:idx], self.buf[idx:]
            lineno += 1

            # now parse the line into tokens ----
            if this_line.startswith('#'):
                yield ( TOKEN_COMMENT, this_line[:-1], (lineno,0), (lineno, len(this_line)-1), this_line )
                yield ( TOKEN_NEWLINE, this_line[-1:], (lineno,len(this_line)-1), (lineno, len(this_line)), this_line )
            elif this_line==newline:
                yield ( TOKEN_NEWLINE, this_line, (lineno,0), (lineno, 1), this_line )
            else:
                parts = this_line.split(' ')
                if len(parts[-1]) > 1 and parts[-1].endswith( newline ):
                    # split newline into its own part if present
                    parts[-1] = parts[-1][:-1]
                    parts.append('\n')

                maybe_comma_part_idx = len(parts)-2 if len(parts) >= 2 else None

                colno = 0
                for part_idx, part in enumerate(parts):
                    startcol = colno
                    endcol = len(part)+startcol
                    colno = endcol + 1

                    if part_idx == maybe_comma_part_idx:
                        if len(part) > 1 and part.endswith(','):
                            # Remove the comma from further processing
                            part = part[:-1]
                            endcol -= 1
                            # Emit a comma token.
                            yield ( TOKEN_COMMA, part, (lineno,endcol), (lineno, endcol+1), this_line )

                    if part in ['{','}']:
                        yield ( TOKEN_OP, part, (lineno,startcol), (lineno, endcol), this_line )
                    elif part==newline:
                        yield ( TOKEN_NEWLINE, part, (lineno,startcol-1), (lineno, endcol-1), this_line )
                    elif part=='':
                        continue
                    elif is_number(part):
                        yield ( TOKEN_NUMBER, part, (lineno,startcol), (lineno, endcol), this_line )
                    elif is_name(part):
                        yield ( TOKEN_NAME, part, (lineno,startcol), (lineno, endcol), this_line )
                    elif is_string_literal(part):
                        yield ( TOKEN_STRING, part, (lineno,startcol), (lineno, endcol), this_line )
                    else:
                        raise NotImplementedError( 'cannot tokenize part %r (line %r)'%(part, this_line) )
        yield ( TOKEN_ENDMARKER, '', (lineno,0), (lineno, 0), '' )

def parse_ascii_data(buf):
    s = StringIO(buf)
    return np.genfromtxt(s,dtype=None)

def parse_binary_data(buf,dtype):
    n_bytes = len(buf)
    n_elements = n_bytes//4 # 4 bytes per float/int32
    n_vectors = n_elements//3 # 3 elements per vector
    result = np.fromstring(buf, dtype=dtype)
    result.shape = (n_vectors, 3)
    if sys.byteorder=='little':
        result = result.byteswap()
    return result

def atom( src, token ):
    if token[0]==TOKEN_NAME:
        name = token[1]
        if name in ARRAY_FIELDS:
            next_token = next(src)
            assert next_token[0]==TOKEN_NUMBER
            n_vectors = int(next_token[1])
            next_token = next(src)
            assert next_token[0]==TOKEN_NEWLINE
            next_token = next(src)
            assert next_token[0]==TOKEN_Vec3Array
            value = next_token[1]
            assert len(value)==n_vectors
        else:
            next_token = next(src)
            if next_token[0]==TOKEN_OP:
                value = atom( src, next_token )
            elif next_token[0]==TOKEN_NAME:
                # name that follows a name is actually a string literal
                value = next_token[1]
            else:
                # potentially a sequence of numbers.
                value = []
                count = 0
                while not (next_token[0] in (TOKEN_NEWLINE,TOKEN_COMMENT)):
                    value.append( atom( src, next_token ) )
                    count += 1
                    next_token = next(src)
                if count==1:
                    value = value[0]
        result = {name: value}
    elif token[0]==TOKEN_OP:
        if token[1]=='{':
            result = {}
            while True:
                next_token = next(src)
                if (next_token[0]==TOKEN_OP and next_token[1]=='}'):
                    break
                if (next_token[0]==TOKEN_NEWLINE):
                    continue
                keyvalue = atom( src, next_token )
                result.update( keyvalue )
        else:
            raise ValueError('unexpected op token: %r'%(token[1],))
    elif token[0]==TOKEN_NUMBER:
        try:
            value = int(token[1])
        except ValueError:
            value = float(token[1])
        result = value
    elif token[0]==TOKEN_STRING:
        value = token[1]#[1:-1]
        result = value
    elif token[0] in [TOKEN_COMMENT, TOKEN_NEWLINE, TOKEN_COMMA]:
        return None
    else:
        raise ValueError('unexpected token type: %r'%(token[0],))
    return result

def filter_comments_and_newlines( generator ):
    for token in generator:
        if token[0] not in (TOKEN_COMMENT,TOKEN_NEWLINE):
            yield token

def read_surf( fileobj ):
    """load a surf file"""

    src = Tokenizer( fileobj ).get_tokens()

    token = next(src)
    result = []
    while token[0] != TOKEN_ENDMARKER:
        this_atom = atom(src, token )
        if this_atom is not None:
            result.append( this_atom )
        token = next(src)

    return result

if __name__=='__main__':
    filename = sys.argv[1]
    with open(filename,mode='rb') as fileobj:
        surf = read_surf( fileobj )
    for row in surf:
        print row
