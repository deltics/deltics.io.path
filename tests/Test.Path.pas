
{$i deltics.inc}

  unit Test.Path;

interface

  uses
    Deltics.Smoketest;


  type
    PathTests = class(TTest)
      procedure AbsoluteReturnsAbsolutePathUnmodified;
      procedure AbsoluteReturnsRelativePathAsAbsolute;
      procedure AbsoluteToRelative;
      procedure AbsoluteToRelativeRaisesEPathExceptionIfPathIsNotAbsolute;
      procedure Append;
      procedure Branch;
      procedure IsAbsolute;
      procedure IsRelative;
      procedure Leaf;
      procedure MakePath;
      procedure RelativeToAbsolute;
      procedure Volume;
    end;



implementation

  uses
    Deltics.IO.Path;



{ PathTests }

  procedure PathTests.AbsoluteReturnsAbsolutePathUnmodified;
  var
    s: String;
  begin
    s := Path.Absolute('c:\thisIsAbsolute', 'c:\root');

    Test('Absolute(<absolute>)').Assert(s).Equals('c:\thisIsAbsolute');
  end;



  procedure PathTests.AbsoluteReturnsRelativePathAsAbsolute;
  var
    s1, s2, s3: String;
  begin
    s1 := Path.Absolute('\thisIsRelative', 'c:\root\sub');
    s2 := Path.Absolute('.\thisIsRelative', 'c:\root\sub');
    s3 := Path.Absolute('..\thisIsRelative', 'c:\root\sub');

    Test('Absolute(<\relative>, c:\root\sub)').Assert(s1).Equals('c:\thisIsRelative');
    Test('Absolute(<.\relative>, c:\root\sub)').Assert(s2).Equals('c:\root\sub\thisIsRelative');
    Test('Absolute(<.\relative>, c:\root)').Assert(s3).Equals('c:\root\thisIsRelative');
  end;


  procedure PathTests.AbsoluteToRelative;
  var
    s1, s2, s3: String;
  begin
    s1 := Path.AbsoluteToRelative('c:\thisIsRelative', 'c:\root\sub');
    s2 := Path.AbsoluteToRelative('c:\root\sub\thisIsRelative', 'c:\root\sub');
    s3 := Path.AbsoluteToRelative('c:\root\thisIsRelative', 'c:\root\sub');

    Test('AbsoluteToRelative(<c:\relative>, c:\root\sub)').Assert(s1).Equals('..\..\thisIsRelative');
    Test('AbsoluteToRelative(<c:\root\sub\relative>, c:\root\sub)').Assert(s2).Equals('.\thisIsRelative');
    Test('AbsoluteToRelative(<c:\root\relative>, c:\root\sub)').Assert(s3).Equals('..\thisIsRelative');
  end;


  procedure PathTests.AbsoluteToRelativeRaisesEPathExceptionIfPathIsNotAbsolute;
  begin
    Test.Raises(EPathException);

    Path.AbsoluteToRelative('\thisIsRelative', 'c:\root\sub');
  end;


  procedure PathTests.Append;
  var
    s: String;
  begin
    s := Path.Append('', '');
    Test('Append(<empty>, <empty>)').Assert(s).Equals('');

    s := Path.Append('', 'sub');
    Test('Append(<empty>, sub)').Assert(s).Equals('sub');

    s := Path.Append('base', '');
    Test('Append(base, <empty>)').Assert(s).Equals('base');

    s := Path.Append('root', 'sub');
    Test('Append(root, sub)').Assert(s).Equals('root\sub');

    s := Path.Append('root\', 'sub');
    Test('Append(root\, sub)').Assert(s).Equals('root\sub');

    s := Path.Append('root\', '\sub');
    Test('Append(root\, \sub)').Assert(s).Equals('root\sub');

    s := Path.Append('root', '\sub');
    Test('Append(root, \sub)').Assert(s).Equals('root\sub');
  end;


  procedure PathTests.Branch;
  var
    s: String;
  begin
    s := Path.Branch('');
    Test('Branch(<empty>)').Assert(s).Equals('');

    s := Path.Branch('\');
    Test('Branch(\)').Assert(s).IsEmpty;

    s := Path.Branch('\\');
    Test('Branch(\\)').Assert(s).Equals('\');

    s := Path.Branch('foo\bar');
    Test('Branch(foo\bar)').Assert(s).Equals('foo');

    s := Path.Branch('foo\bar\none');
    Test('Branch(foo\bar\none)').Assert(s).Equals('foo\bar');
  end;


  procedure PathTests.IsAbsolute;
  var
    result: Boolean;
  begin
    result := Path.IsAbsolute('c:\folder');
    Test('IsAbsolute(c:\folder)').Assert(result).IsTrue;

    result := Path.IsAbsolute('\\host\share\folder');
    Test('IsAbsolute(\\host\share\folder)').Assert(result).IsTrue;

    result := Path.IsAbsolute('\folder');
    Test('IsAbsolute(\folder)').Assert(result).IsFalse;
  end;


  procedure PathTests.IsRelative;
  var
    result: Boolean;
  begin
    result := Path.IsRelative('c:\folder');
    Test('IsRelative(c:\folder)').Assert(result).IsFalse;

    result := Path.IsRelative('\\host\share\folder');
    Test('IsRelative(\\host\share\folder)').Assert(result).IsFalse;

    result := Path.IsRelative('\folder');
    Test('IsRelative(\folder)').Assert(result).IsTrue;

    result := Path.IsRelative('.\folder');
    Test('IsRelative(.\folder)').Assert(result).IsTrue;

    result := Path.IsRelative('..\folder');
    Test('IsRelative(..\folder)').Assert(result).IsTrue;
  end;


  procedure PathTests.Leaf;
  var
    s: String;
  begin
    s := Path.Leaf('');
    Test('Leaf(<empty>)').Assert(s).IsEmpty;

    s := Path.Leaf('\');
    Test('Leaf(\)').Assert(s).IsEmpty;

    s := Path.Leaf('\\');
    Test('Leaf(\\)').Assert(s).IsEmpty;

    s := Path.Leaf('foo\bar');
    Test('Leaf(foo\bar)').Assert(s).Equals('bar');

    s := Path.Leaf('foo\bar\none');
    Test('Leaf(foo\bar\none)').Assert(s).Equals('none');
  end;


  procedure PathTests.MakePath;
  var
    s: String;
  begin
    s := Path.MakePath(['foo', 123, 'bar']);
    Test('MakePath([foo, 123, bar]>)').Assert(s).Equals('foo\123\bar');
  end;


  procedure PathTests.RelativeToAbsolute;
  var
    s1, s2, s3: String;
  begin
    s1 := Path.RelativeToAbsolute('.\thisIsRelative', 'c:\root\sub');
    s2 := Path.RelativeToAbsolute('..\thisIsRelative', 'c:\root\sub');
    s3 := Path.RelativeToAbsolute('\thisIsRelative', 'c:\root\sub');

    Test('RelativeToAbsolute(<.\relative>, c:\root\sub)').Assert(s1).Equals('c:\root\sub\thisIsRelative');
    Test('RelativeToAbsolute(<..\root\sub\relative>, c:\root\sub)').Assert(s2).Equals('c:\root\thisIsRelative');
    Test('RelativeToAbsolute(<\root\relative>, c:\root\sub)').Assert(s3).Equals('c:\thisIsRelative');
  end;


  procedure PathTests.Volume;
  var
    s: String;
  begin
    s := Path.Volume('c:\path');
    Test('Volume(c:\path)').Assert(s).Equals('c:');

    s := Path.Volume('\\host\share\path');
    Test('Volume(\\host\share\path)').Assert(s).Equals('\\host\share');
  end;




end.
