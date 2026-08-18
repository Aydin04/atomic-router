@echo off
title AtomicRouter Universal AI Gateway
set PORT=20128
if not exist .env (
  if exist .env.example (
    copy .env.example .env >nul 2>&1
  ) else (
    echo PORT=20128 > .env
  )
)
echo ========================================================
echo   ⚡ AtomicRouter Universal AI Gateway
echo   Dashboard: http://localhost:20128/
echo ========================================================
node server.js
pause
