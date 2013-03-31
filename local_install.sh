#!/usr/bin/env bash

zip -r haxelib.zip src/*
haxelib local haxelib.zip
