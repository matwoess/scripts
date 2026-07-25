#!/bin/bash
hfile=~/.zsh/histfile
mv $hfile{,.corr}
strings $hfile.corr > $hfile
fc -R $hfile
