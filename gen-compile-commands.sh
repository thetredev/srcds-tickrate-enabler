#!/bin/bash

ENGINE=${1}

make -B ENGINE=${ENGINE} -n shared-lib | tr '\t' ' ' | sed ':a;N;$!ba;s/\\\n/ /g' | sed 's/[[:space:]]\+/ /g' | jq -R -s -r '
split("\n")
| map(select(test("^g\\+\\+")))
| map(
    . as $cmd
    | {
        directory: "/home/cheeba/repo/github.com/thetredev/srcds-tickrate-enabler",
        command: $cmd,

        file: (
            if $cmd | test(" -c ")
            then ($cmd | capture("-c (?<f>[^ ]+)").f)
            else null
            end
        ),

        output: (
            if $cmd | test(" -o ")
            then ($cmd | capture("-o (?<o>[^ ]+)").o)
            else null
            end
        )
    }
)
' > compile_commands.json
