use path
use str

set file-name = '.env'

fn -parse-line [line]{
    set name value = (str:split &max=2 '=' $line)

    str:trim-space $name
    str:trim-space $value
}

fn -parse [lines]{
    env = [&]

    for line $lines {
        set line = (str:trim-space $line)

        if (or (eq $line '') (str:has-prefix $line '#')) {
            continue
        }

        name value = (-parse-line $line)

        set env[$name] = $value
    }

    put $env
}

fn parse-file [path]{
    if (not (path:is-regular $path)) {
        fail
    }

    -parse [(cat $path)]
}

fn load-file [path]{
    if (not (path:is-regular $path)) {
        fail
    }

    set env = (parse-file $path)

    for name [(keys $env)] {
        set-env $name $env[$name]
    }
}

fn load [&path=$file-name]{
    if (not (path:is-regular $path)) {
        return
    }

    load-file $path
}

fn exec [&path=$file-name script]{
    if (not (path:is-regular $path)) {
        return
    }

    set env = (parse-file $path)
    set original = (each [name]{
        if (has-env $name) {
            put [$name (get-env $name)]
        }

        set-env $name $env[$name]
    } [(keys $env)] | make-map)

    eval $cmd

    for name [(keys $env)] {
        if (has-key $original $name) {
            set-env $name $original[$name]
        } else {
            unset-env $name
        }
    }
}
