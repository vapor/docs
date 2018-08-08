# -*- coding: utf-8 -*-
"""
    pygments.lexers.leaf
    ~~~~~~~~~~~~~~~~~~~~

    Lexer for Leaf markup.
"""

import re

from pygments.lexer import RegexLexer, ExtendedRegexLexer, include, bygroups, default, using
from pygments.token import Text, Comment, Operator, Keyword, Name, String, Punctuation, Number

__all__ = ['LeafLexer']

class LeafLexer(RegexLexer):
    name = 'Leaf'
    aliases = ['leaf']
    filenames = ['*.leaf']
    mimetypes = ['text/leaf', 'application/leaf']
    tokens = {
        'root': [
            (r'\n', Comment),
            (r'\s+', Comment),
            (r'else', Keyword),
            (r'#\/\/.*', String),
            (r'#\/\*[^\*]*\*\/', String),
            (r'if\(|if\ \(', Keyword, 'expression'),
            (r'(\#)([^\(]*)(\()', bygroups(Keyword, Keyword, Punctuation), 'expression'),
            (r'\{', Name.Builtin.Pseudo),
            (r'\}', Name.Builtin.Pseudo),
            (r'[^\#\}]+', Comment),
        ],
        'expression': [
            (r'\s+', Text),
            (r'(")([^"]+)(")', String),
            (r'[\d]+', Number.Int),
            (r'in', Keyword),
            (r',', Text),
            (r'[\=\!\|\&\+\-\*\%]+', Operator),
            (r'[\w]+(?=\()', Name.Builtin.Pseudo),
            (r'[\w]+', Text),
            (r'\(', Text, '#push'),
            (r'\)', Text, '#pop'),
        ]
    }

