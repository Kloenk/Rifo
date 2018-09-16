#!/bin/bash
shopt -s nullglob globstar
prefix=${PASSWORD_STORE_DIR-~/.password-store}
password_files=( "$prefix"/**/*.gpg )
password_files=( "${password_files[@]%.gpg}" )
password_files=( "${password_files[@]#"$prefix"/}" )
printf '%s\n' "${password_files[@]}" 
shopt -u nullglob globstar
