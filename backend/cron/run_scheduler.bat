@echo off
REM Windows Task Scheduler Runner for PMS Daily Rent Scheduler
REM Schedule this task in Windows Task Scheduler to run daily at 00:05 (or 01:00)

set PHP_BIN=d:\xamp\php\php.exe
if not exist "%PHP_BIN%" (
    set PHP_BIN=C:\xampp\php\php.exe
)

"%PHP_BIN%" "%~dp0daily_rent_scheduler.php"
"%PHP_BIN%" "%~dp0daily_compliance_scheduler.php"
