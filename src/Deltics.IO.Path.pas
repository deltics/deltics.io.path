
{$i deltics.io.path.inc}

  unit Deltics.IO.Path;


interface

  uses
    SysUtils,
    Deltics.Exceptions,
    Deltics.Uri;


  type
    EPathException = class(Exception);


    Path = class
    public
      class function Absolute(const aPath: String; const aRootPath: String = ''): String;
      class function AbsoluteToRelative(const aPath: String; const aBasePath: String = ''): String;
      class function Append(const aBase, aExtension: String): String;
      class function Branch(const aPath: String): String;
      class function CurrentDir: String;
      class function Exists(const aPath: String): Boolean;
      class function IsAbsolute(const aPath: String): Boolean;
      class function IsRelative(const aPath: String): Boolean;
      class function Leaf(const aPath: String): String;
      class function MakePath(const aElements: array of const): String;
      class function PathFromUri(const aUri: IUri): String; overload;
      class function PathFromUri(const aUri: String): String; overload;
      class function RelativeToAbsolute(const aPath: String; const aRootPath: String = ''): String;
      class function Volume(const aAbsolutePath: String): String;
    end;



implementation

  uses
    Deltics.ConstArrays,
    Deltics.Strings;



  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Absolute(const aPath, aRootPath: String): String;
  begin
    if IsAbsolute(aPath) then
      result := aPath
    else
      result := RelativeToAbsolute(aPath, aRootPath);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.AbsoluteToRelative(const aPath, aBasePath: String): String;
  var
    base: String;
    stem: String;
    nav: String;
  begin
    if NOT IsAbsolute(aPath) then
      raise EPathException.CreateFmt('''%s'' is not an absolute path', [aPath]);

    result := aPath;

    base := aBasePath;
    if base = '' then
      base := Path.CurrentDir;

    // If it is a sub-directory of the base path then we can just remove the base path
    //  and prepend the "current directory" navigation
    if STR.BeginsWithText(aPath, base) then
    begin
      result := '.\' + Copy(aPath, Length(base) + 2, Length(aPath) - Length(base));
      EXIT;
    end;

    // Otherwise, let's try progressively jumping up to parent directories and
    //  if we eventually find a common root we can add directory navigation to
    //  the relative path
    stem  := base;
    nav   := '';
    while (stem <> '') do
    begin
      stem := Branch(stem);
      if nav <> '' then
        nav  := '..\' + nav
      else
        nav := '..';

      if STR.BeginsWithText(aPath, stem) then
      begin
        result := nav + '\' + Copy(aPath, Length(stem) + 2, Length(aPath) - Length(stem) + 1);
        BREAK;
      end;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Append(const aBase, aExtension: String): String;
  begin
    if aBase = '' then
      result := aExtension
    else if aExtension = '' then
      result := aBase
    else
    begin
      result := aBase;

      if aExtension[1] = '\' then
      begin
        if result[Length(result)] = '\' then
          SetLength(result, Length(result) - 1);
      end
      else if result[Length(result)] <> '\' then
        result := result + '\';

      result := result + aExtension;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Branch(const aPath: String): String;
  {
    Returns the path containing the specified path or an empty
     string if the specified path has no identifiable branch.

    Examples:

        Branch( 'abc\def\ghi' )  ==> 'abc\def'
        Branch( 'abc' )          ==> ''
  }
  begin
    if Pos('\', aPath) <> 0 then
    begin
      result := ExtractFilePath(aPath);
      SetLength(result, Length(result) - 1);
    end
    else
      result := '';
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.CurrentDir: String;
  begin
    result := GetCurrentDir;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Exists(const aPath: String): Boolean;
  var
    target: UnicodeString;
  begin
    target := aPath;

    if NOT Path.IsAbsolute(target) then
      target := RelativeToAbsolute(target);

    result := DirectoryExists(target);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.IsAbsolute(const aPath: String): Boolean;
  begin
    result := (Copy(aPath, 1, 2) = '\\')
           or (Copy(aPath, 2, 2) = ':\');
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.IsNavigation(const aPath: String): Boolean;
  begin
    case Length(aPath) of
      1 : result := aPath[1] = '.';

      2 : result := (aPath[1] = '.') and (aPath[2] = '.');
    else
      result := FALSE;
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.IsRelative(const aPath: String): Boolean;
  begin
    result := NOT IsAbsolute(aPath);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Leaf(const aPath: String): String;
  {
    Returns the file or folder identified by the specified path.

    Examples:

        Leaf( 'abc\def\ghi' )  ==> 'ghi'
  }
  begin
    result := ExtractFilename(aPath);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.MakePath(const aElements: array of const): String;
  var
    i: Integer;
    strs: StringArray;
  begin
    result := '';
    SetLength(strs, 0);
    if Length(aElements) = 0 then
      EXIT;

    strs := ConstArray.AsStringArray(aElements);
    result := strs[0];
    for i := 1 to High(strs) do
      result := Path.Append(result, strs[i]);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.PathFromUri(const aUri: String): String;
  var
    uri: IUri;
  begin
    uri     := TUri.Create(aUri);
    result  := uri.AsFilePath;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.PathFromUri(const aUri: IUri): String;
  begin
    result := aUri.AsFilePath;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.RelativeToAbsolute(const aPath: String;
                                         const aRootPath: String): String;
  var
    cd: String;
  begin
    result := aPath;
    try
      if IsAbsolute(aPath) then
        EXIT;

      if aRootPath = '' then
        cd := GetCurrentDir
      else
        cd := aRootPath;

      if NOT IsAbsolute(cd) then
        raise EPathException.Create('Specified root for relative path must be a fully qualified path (UNC or drive letter)');

      if cd[Length(cd)] = '\' then
        SetLength(cd, Length(cd) - 1);

      if (aPath = '.') or (aPath = '.\') then
      begin
        result := cd;
        EXIT;
      end;

      if aPath = '..' then
      begin
        result := Branch(cd);
        EXIT;
      end;

      if aPath[1] = '\' then
      begin
        result := Path.Volume(cd) + aPath;
      end
      else if Copy(aPath, 1, 3) = '..\' then
      begin
        result := aPath;
        repeat
          Delete(result, 1, 3);
          cd := Branch(cd)
        until Copy(result, 1, 2) <> '..';

        result := cd + '\' + result;
      end
      else if Copy(aPath, 1, 2) = '.\' then
      begin
        result := aPath;
        Delete(result, 1, 2);
        result := cd + '\' + result;
      end
      else
        result := cd + '\' + aPath;

    finally
      if (Length(result) > 0) and STR.EndsWith(result, '\') then
        STR.DeleteRight(result, 1);
    end;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  class function Path.Volume(const aAbsolutePath: String): String;
  var
    i: Integer;
    target: String;
  begin
    target := aAbsolutePath;

    if NOT Path.IsAbsolute(target) then
      raise EPathException.Create('Specified path must be a fully qualified path (UNC or drive letter)');

    if target[2] = ':' then
    begin
      result := Copy(target, 1, 2);
      EXIT;
    end;

    if Copy(target, 1, 2) = '\\' then
    begin
      Delete(target, 1, 2);
      result := '\\';

      i := Pos('\', target);
      if i > 0 then
      begin
        result := result + Copy(target, 1, i);
        Delete(target, 1, i);

        i := Pos('\', target);
        if i > 0 then
        begin
          result := result + Copy(target, 1, i - 1);
          EXIT;
        end;
      end;
    end;

    raise EPathException.CreateFmt('''%s'' is not a fully qualified path (UNC or drive letter)', [aAbsolutePath]);
  end;





end.
