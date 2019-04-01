@echo off


if "%ALIASES%" == "" (
  set ALIASES="%CMDER_ROOT%\config\user_aliases.cmd"
)

setlocal enabledelayedexpansion

if "%~1" == "" echo Use /? for help & echo. & goto :p_show

:: check command usage

rem #region parseargument
goto parseargument

set args=

:do_shift
  shift

:parseargument
  set currentarg=%~1

  if /i "%currentarg%" equ "/f" (
    set ALIASES=%~2
    set ALT_ALIASES=%~2
    shift
    goto :do_shift
  ) else if /i "%currentarg%" == "/reload" (
    goto :p_reload
  ) else if "%currentarg%" equ "/H" (
    goto :p_help
  ) else if "%currentarg%" equ "/h" (
    goto :p_help
  ) else if "%currentarg%" equ "/?" (
    goto :p_help
  ) else if /i "%currentarg%" equ "/d" (
    if "%~2" neq "" (
      if "%~3" equ "" (
        :: /d flag for delete existing alias
        call :p_del %~2
        shift
        goto :eof
      )
    )
  ) else if "%currentarg%" neq "" (
    if "%~2" equ "" (
      :: Show the specified alias
      doskey /macros | %WINDIR%\System32\findstr /b %currentarg%= && exit /b
      echo insufficient parameters.
      goto :p_help
    ) else if "%currentarg%" == "create" (
      set action=create
      if [%ALT_ALIASES%] neq [] (
        echo 1
        for /f "tokens=1,2,3,* usebackq" %%G in (`echo %*`) do (
          set args=%%J
        )
      ) else (
        echo 2
        for /f "tokens=1,2,* usebackq" %%G in (`echo %*`) do (
          set args=%%H %%I
        )
      )
    ) else (
      :: handle quotes within command definition, e.g. quoted long file names
      set _x=%*
    )
  )

:: echo _x=%_x%
:: echo args=%args%

rem #endregion parseargument

if "%ALIASES%" neq "%CMDER_ROOT%\config\user_aliases.cmd" (
  set _x=!_x:/f "%ALIASES%" =!

  if not exist "%ALIASES%" (
    echo ;= @echo off>"%ALIASES%"
    echo ;= rem Call DOSKEY and use this file as the macrofile>>"%ALIASES%"
    echo ;= %%SystemRoot%%\system32\doskey /listsize=1000 /macrofile=%%0%%>>"%ALIASES%"
    echo ;= rem In batch mode, jump to the end of the file>>"%ALIASES%"
    echo ;= goto:eof>>"%ALIASES%"
    echo ;= Add aliases below here>>"%ALIASES%"
  )
)

:: create with multiple parameters
if [%action%] == [create] (
  if not ["%args%"] == [""] (
    for /f "tokens=1,* usebackq" %%G in (`echo %args%`) do (
      set alias_name=%%G
      set alias_value=%%H
    )
  )
) else (
  :: validate alias
  echo %_x%
  set x=!_x:%=^^%!
  echo !_x!
  for /f "delims== tokens=1,* usebackq" %%G in (`echo "!_x!"`) do (
    set alias_name=%%G
    set alias_value=%%H
  )

  :: leading quotes added while validating
  set alias_name=!alias_name:~1!
  
  :: trailing quotes added while validating
  set alias_value=!alias_value:~1,-1!
)

::remove spaces
set _temp=%alias_name: =%

if not ["%_temp%"] == ["%alias_name%"] (
  echo Your alias name can not contain a space
  endlocal
  exit /b
)

:: replace already defined alias
%WINDIR%\System32\findstr /b /v /i "%alias_name%=" "%ALIASES%" >> "%ALIASES%.tmp"
echo %alias_name%=%alias_value% >> "%ALIASES%.tmp" && type "%ALIASES%.tmp" > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey /macrofile="%ALIASES%"
endlocal
exit /b

:p_del
set del_alias=%~1
%WINDIR%\System32\findstr /b /v /i "%del_alias%=" "%ALIASES%" >> "%ALIASES%.tmp"
type "%ALIASES%".tmp > "%ALIASES%" & @del /f /q "%ALIASES%.tmp"
doskey %del_alias%=
doskey /macrofile="%ALIASES%"
goto:eof

:p_reload
doskey /macrofile="%ALIASES%"
echo Aliases reloaded
exit /b

:p_show
doskey /macros|%WINDIR%\System32\findstr /v /r "^;=" | sort
exit /b

:p_help
echo.Usage:
echo.
echo.     alias [options] [alias=alias command] or [[create [alias] [alias command]]]
echo.
echo.Options:
echo.
echo.     Note: Options MUST precede the alias definition.
echo.
echo.     /d [alias]     Delete an [alias].
echo.     /f [macrofile] Path to the [macrofile] you want to store the new alias in.
echo.                    Default: %cmder_root%\config\user_aliases.cmd
echo.     /reload        Reload the aliases file.  Can be used with /f argument.
echo.                    Default: %cmder_root%\config\user_aliases.cmd
echo.
echo. If alias is called with no parameters, it will display the list of existing aliases.
echo.
echo. In the alias command, you can use the following notations:
echo.
echo. ^^^^^^^^%% - '%%' in env vars must be escaped if preserving the variable in the alias is desired.
echo. $*    - allows the alias to assume all the parameters of the supplied command.
echo. $1-$9 - Allows you to seperate parameter by number, much like %%1 in batch.
echo. $T    - Command seperator, allowing you to string several commands together into one alias.
echo.
echo. For more information, read DOSKEY /?
exit /b
