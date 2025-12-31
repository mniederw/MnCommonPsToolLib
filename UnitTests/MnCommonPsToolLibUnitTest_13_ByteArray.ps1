#!/usr/bin/env pwsh

Import-Module -NoClobber -Name "MnCommonPsToolLib.psm1"; Set-StrictMode -Version Latest; trap [Exception] { StdErrHandleExc $_; break; }

function UnitTest_ByteArray(){
  OutProgress (ScriptGetCurrentFuncName);
  Assert         ((ByteArraysAreEqual @()               @()              ) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01,0xFF)) -eq $true );
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x02,0xFF)) -eq $false);
  Assert         ((ByteArraysAreEqual @(0x00,0x01,0xFF) @(0x00,0x01     )) -eq $false);
}
UnitTest_ByteArray;
