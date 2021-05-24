use str
use re

fn -shell-var [line]{
  index = (str:index $line '=')

  if (== $index -1) {
    fail 'invalid shell variable assignment'
  }

  put [
    &name=(str:trim-space $line[..$index])
    &value=(str:trim-space $line[(+ $index 1)..])
  ]
}

fn -monitor-lines []{
  e:xrandr --query | each [a]{
    if (str:contains $a 'connected') {
      put $a
    }
  }
}

fn -parse-monitor-line [line]{
  monitor = [
    &name=$line[0..(str:index $line ' ')]
    &connected=(not (str:contains $line 'disconnected'))
    &primary=(str:contains $line 'primary')
  ]

  if $monitor[connected] {
    mode = (re:find &max=1 '(\d+)x(\d+)\+(\d+)(?:\+(\d+))?' $line)[groups]

    monitor[width] = (num $mode[1][text])
    monitor[height] = (num $mode[2][text])
    monitor[x] = (num $mode[3][text])
    monitor[y] = (
      if (has-key $mode 3) {
        num 0
      } else {
        num $mode[3]
      }
    )
  }

  put $monitor
}

fn window [id]{
  name _ x y width height screen = (e:xdotool getwindowname $id getwindowgeometry --shell $id)

  put [
    &name=$name
    &id=$id
    &screen=(num (-shell-var $screen)[value])
    &x=(num (-shell-var $x)[value])
    &y=(num (-shell-var $y)[value])
    &width=(num (-shell-var $width)[value])
    &height=(num (-shell-var $height)[value])
  ]
}

fn active-window []{
  window (e:xdotool getactivewindow)
}

fn monitors []{
  -monitor-lines | each $-parse-monitor-line~
}

fn monitor [name]{
  for monitor-line [(-monitor-lines)] {
    if (==s $name $monitor-line[..(str:index $monitor-line ' ')]) {
      -parse-monitor-line $monitor-line
      return
    }
  }
}

fn monitor-of-window [window]{
  for monitor [(monitors)] {
    if $monitor[connected] {
      after-start = (and (<= $monitor[x] $window[x]) (<= $monitor[y] $window[y]))
      before-end = (and (> (+ $monitor[x] $monitor[width]) $window[x]) (> (+ $monitor[y] $monitor[height]) $window[y]))

      if (and $after-start $before-end) {
        put $monitor
        return
      }
    }
  }

  fail 'unable to determine monitor of window'
}
