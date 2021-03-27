
{$apptype CONSOLE}

  program test;

uses
  Deltics.Smoketest,
  Deltics.IO.Path in '..\src\Deltics.IO.Path.pas',
  Test.Path in 'Test.Path.pas';

begin
  TestRun.Test(PathTests);
end.
