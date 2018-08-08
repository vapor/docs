from distutils.core import setup


setup (
  name='leaf',
  version='0.1.0-dev',
  url='https://github.com/vapor/leaf',
  author='tanner0101',
  author_email='me@tanner.xyz',
  packages=['leaf'],
  entry_points =
  """
  [pygments.lexers]
  leaf = leaf.lexer:LeafLexer
  """,
)